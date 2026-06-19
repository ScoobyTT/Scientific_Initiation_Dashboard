#!/usr/bin/env python
# coding: utf-8

# PREDICTOR — carrega ensemble LSTM (PyTorch) e gera predições futuras de dengue
#
# AVISO (Python 3.14 + PyTorch):
#   Wheels CPU disponíveis. Wheels CUDA para cp314 ainda sem publicação oficial
#   (junho/2026). Veja comentário no trainer.py.
#
# Instalação mínima (CPU):
#   pip install torch --index-url https://download.pytorch.org/whl/cpu
#   pip install numpy pandas matplotlib scikit-learn joblib
#
# Nota: a dependência 'scalecast' foi removida. Ela era importada mas
# não utilizada diretamente na lógica de predição do script original.

import os
import sys
import glob
import re
import argparse

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import joblib

import torch
import torch.nn as nn


# ---------------------------------------------------------------------------
# CALENDÁRIO SINAN: calcula próximas semanas epidemiológicas corretamente
# ---------------------------------------------------------------------------

def load_sinan_calendar(calendar_path: str) -> pd.DataFrame:
    """Lê o calendário SINAN (tab-separado) e retorna DataFrame normalizado."""
    cal = pd.read_csv(calendar_path, sep='\t', dtype=str)
    cal.columns = cal.columns.str.strip()
    cal['SEM_NOT'] = cal['SEM_NOT'].str.strip()
    cal['ANO']     = cal['ANO'].str.strip()
    return cal


def next_epiweeks(last_week_str: str, n: int, calendar_path: str) -> list:
    """
    Dado o código da última semana no formato 'YYYY.NN' (ex: '2025.53'),
    retorna lista com as próximas 'n' semanas no mesmo formato,
    consultando o calendário SINAN para respeitar a virada de ano.

    Fallback simples (com aviso) se o calendário não for encontrado
    ou a semana não estiver nele — pode gerar semanas inválidas
    em anos com 53 semanas.
    """
    def fallback(last: str, n: int) -> list:
        ano, sem = last.split('.')
        ano, sem = int(ano), int(sem)
        result = []
        for _ in range(n):
            sem += 1
            result.append(f"{ano}.{sem:02d}")
        return result

    if not calendar_path or not os.path.exists(calendar_path):
        print(f"AVISO: calendário SINAN não encontrado em '{calendar_path}'. "
              f"Usando fallback (pode gerar semanas inválidas em virada de ano).")
        return fallback(last_week_str, n)

    cal = load_sinan_calendar(calendar_path)
    cal['week_key'] = cal['ANO'] + '.' + cal['SEM_NOT'].str[4:].str.zfill(2)
    keys = cal['week_key'].tolist()

    if last_week_str not in keys:
        print(f"AVISO: semana '{last_week_str}' não encontrada no calendário SINAN. "
              f"Usando fallback.")
        return fallback(last_week_str, n)

    idx    = keys.index(last_week_str)
    result = []
    for i in range(1, n + 1):
        next_idx = idx + i
        if next_idx >= len(keys):
            print(f"AVISO: calendário SINAN não cobre semana futura no índice {next_idx}.")
            break
        result.append(keys[next_idx])

    return result


# ---------------------------------------------------------------------------
# MODELO LSTM (idêntico ao trainer.py — deve ser importado ou copiado)
# ---------------------------------------------------------------------------

class DengueLSTM(nn.Module):
    """
    Deve ser idêntico à definição no trainer.py.
    Mantido aqui por auto-suficiência do script de predição.
    """

    def __init__(self, input_size: int, hidden_size: int, output_size: int):
        super().__init__()
        self.lstm  = nn.LSTM(input_size=input_size,
                             hidden_size=hidden_size,
                             num_layers=1,
                             batch_first=True)
        self.relu  = nn.ReLU()
        self.dense = nn.Linear(hidden_size, output_size)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        out, _ = self.lstm(x)
        last   = out[:, -1, :]
        last   = self.relu(last)
        return self.dense(last)


# ---------------------------------------------------------------------------
# HIPERPARÂMETROS (devem bater com o trainer)
# ---------------------------------------------------------------------------

PREDICTION_INTERVAL = 4
FACT                = int(1 + PREDICTION_INTERVAL / 2)   # = 3
HISTORY_STEP        = 8 + 2 * FACT                        # = 14
LSTM_HIDDEN         = FACT * 120                          # = 360


# ---------------------------------------------------------------------------
# FUNÇÕES AUXILIARES
# ---------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Predictor: usa ensemble LSTM (PyTorch) para prever dengue"
    )
    parser.add_argument("--data_directory",  type=str, required=True)
    parser.add_argument("--model_directory", type=str, required=True)
    parser.add_argument("--country",         type=str, required=True)
    parser.add_argument("--calendar",        type=str, default="",
                        help="Caminho para sinan_calendario.txt")
    return parser.parse_args()


def extract_run_code(path: str) -> str:
    pattern = r'\d{2}\.\d{2}\.\d{4}_\d{2}h'
    match   = re.search(pattern, path)
    if not match:
        print(f"ERRO: run_code não encontrado em: {path}")
        sys.exit(1)
    return match.group()


def load_models(model_dir: str, country: str,
                device: torch.device) -> list:
    """
    Carrega todos os arquivos .pt do diretório que correspondem ao país.
    Retorna lista de modelos em modo eval.
    """
    pattern = os.path.join(model_dir, f"{country}*.pt")
    files   = glob.glob(pattern)
    if not files:
        print(f"ERRO: nenhum modelo .pt encontrado em {pattern}")
        sys.exit(1)

    models = []
    for f in files:
        m = DengueLSTM(input_size=1,
                       hidden_size=LSTM_HIDDEN,
                       output_size=PREDICTION_INTERVAL)
        m.load_state_dict(torch.load(f, map_location=device))
        m.to(device)
        m.eval()
        models.append(m)

    print(f"Carregados {len(models)} modelos para {country}.")
    return models


def correct_discontinuity(d: list, weeks: list, output_path: str,
                           country: str) -> list:
    """
    Detecta e corrige descontinuidade abrupta no final da série de entrada
    por extrapolação polinomial. Reproduz a lógica do predictor original.
    """
    derivada = np.diff(d)
    media    = np.mean(np.abs(derivada))
    std      = np.std(np.abs(derivada))
    cut_off  = media + 2 * std

    nova_serie = d[:]

    if np.max(np.abs(derivada)) <= cut_off:
        return nova_serie

    recuo  = 5
    degree = 2
    nweeks_local = len(d)

    if HISTORY_STEP < recuo + 3:
        recuo = HISTORY_STEP - 3

    cut = 0
    for i, dv in enumerate(derivada):
        if abs(dv) > cut_off:
            cut = i + 1
            break

    if cut < recuo:
        return nova_serie

    print(f"Descontinuidade detectada: primeira semana cortada = {cut}")

    x = np.arange(cut - recuo, cut)
    y = d[cut - recuo:cut]

    coeffs = np.polyfit(x, y, degree)
    a, b, c = coeffs
    n  = int(np.max(x))
    m  = len(d) - cut
    xhat = np.arange(n + 1, n + m + 1)
    yhat = a * xhat**2 + b * xhat + c
    yhat = np.clip(yhat, 0, None)

    nova_serie = list(d[:cut]) + yhat.tolist()

    # Gráfico de correção
    input_ticks = range(nweeks_local - len(d), nweeks_local)
    rotulos     = [weeks[i] for i in input_ticks]
    fig, ax = plt.subplots(figsize=(10, 7))
    ax.plot(list(input_ticks)[:cut],    d[:cut],     "gd-", label="Dados mantidos")
    ax.plot(list(input_ticks)[cut:],    d[cut:],     "r.-", label="Dados originais (descartados)")
    ax.plot(list(input_ticks)[cut:],    yhat,        "yd-", label="Dados corrigidos")
    ax.plot(list(input_ticks),          nova_serie,  "k.:", label="Série reconstruída")
    ax.set_xticks(list(input_ticks))
    ax.set_xticklabels(rotulos, rotation=45)
    ax.set_xlabel("Semanas de entrada")
    ax.set_ylabel("Casos")
    ax.legend()
    ax.grid(True)
    ax.set_title("Correção de descontinuidade na série de entrada")
    fig.savefig(os.path.join(output_path, f"{country}_input_data_modifications.jpeg"),
                format='jpeg', dpi=300)
    plt.close(fig)

    return nova_serie


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

def main():
    args          = parse_args()
    country       = args.country.strip()
    data_dir      = args.data_directory.strip()
    model_dir     = args.model_directory.strip()
    calendar_path = args.calendar.strip() if args.calendar else ""

    data_run_code  = extract_run_code(data_dir)
    model_run_code = extract_run_code(model_dir)
    print(f"data_run_code:  {data_run_code}")
    print(f"model_run_code: {model_run_code}")

    # --- localiza CSV ---------------------------------------------------
    pattern   = os.path.join(data_dir, f"{country}_*.csv")
    all_files = glob.glob(pattern)
    if not all_files:
        print(f"ERRO: nenhum CSV encontrado em {pattern}")
        sys.exit(1)
    if len(all_files) > 1:
        print("ERRO: múltiplos CSVs encontrados.")
        sys.exit(1)

    filename = all_files[0]
    print(f"Arquivo encontrado: {filename}")

    data   = pd.read_csv(filename)
    series = data['Smoothed Dengue Cases'].values.reshape(-1, 1)
    weeks  = [w.replace("'", "") for w in data["Date"].tolist()]
    nweeks = len(weeks)
    print(f"Semanas no dataset: {nweeks}  ({weeks[0]} → {weeks[-1]})")

    # --- scaler ---------------------------------------------------------
    scaler_path = os.path.join(model_dir, f"{country}_scaler.pkl")
    scaler = joblib.load(scaler_path)

    # --- diretório de saída -------------------------------------------
    output_path = os.path.join("..", "results", "predictions",
                               f"DATA_{data_run_code}_MODEL_{model_run_code}")
    os.makedirs(output_path, exist_ok=True)
    print(f"Saída: {output_path}")

    # --- carrega modelos ------------------------------------------------
    # device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    
    if torch.backends.mps.is_available():
        device = torch.device("mps")
    elif torch.cuda.is_available():
        device = torch.device("cuda")
    else:
        device = torch.device("cpu")

    print(f"Dispositivo: {device}")

    # if str(device) == "cpu" and sys.version_info >= (3, 14):
    #     print("AVISO: Wheels CUDA para Python 3.14 ainda não publicadas (junho/2026). "
    #          "Inferência rodando em CPU.")

    models = load_models(model_dir, country, device)

    # verifica comprimento mínimo
    if nweeks < HISTORY_STEP:
        print(f"ERRO: série muito curta ({nweeks} semanas). Mínimo: {HISTORY_STEP}.")
        sys.exit(1)

    # --- extrai janela de entrada ---------------------------------------
    input_data  = series[-HISTORY_STEP:].flatten().tolist()
    input_weeks = weeks[-HISTORY_STEP:]

    # semanas de saída — consulta calendário SINAN para respeitar virada de ano
    output_weeks = next_epiweeks(weeks[-1], PREDICTION_INTERVAL, calendar_path)
    if len(output_weeks) < PREDICTION_INTERVAL:
        print(f"ERRO: não foi possível gerar {PREDICTION_INTERVAL} semanas futuras "
              f"a partir de '{weeks[-1]}'.")
        sys.exit(1)
    tot_weeks = weeks + output_weeks

    print(f"Semanas de entrada: {input_weeks[0]} → {input_weeks[-1]}")
    print(f"Semanas preditas:   {output_weeks[0]} → {output_weeks[-1]}")

    # --- corrige descontinuidade ----------------------------------------
    corrected = correct_discontinuity(input_data, weeks, output_path, country)
    input_arr = np.array(corrected).reshape(-1, 1)

    # --- normaliza e formata para LSTM ----------------------------------
    scaled = scaler.transform(input_arr)                  # (HISTORY_STEP, 1)
    tensor = torch.tensor(scaled, dtype=torch.float32)
    tensor = tensor.unsqueeze(0)                          # (1, HISTORY_STEP, 1)
    tensor = tensor.to(device)

    # --- predição com todos os modelos ----------------------------------
    Predictions = []
    for m in models:
        with torch.no_grad():
            out_scaled = m(tensor).cpu().numpy()          # (1, PREDICTION_INTERVAL)
        out_scaled = np.clip(out_scaled, 0, None)
        out = scaler.inverse_transform(out_scaled)        # (1, PREDICTION_INTERVAL)
        Predictions.append(out[0])

    mean_pred = np.mean(Predictions, axis=0)
    std_pred  = np.std(Predictions,  axis=0)
    upper     = mean_pred + 2 * std_pred
    lower     = np.clip(mean_pred - 2 * std_pred, 0, None)

    # --- gráfico de predição -------------------------------------------
    prev_data   = HISTORY_STEP
    prev_series = series[-HISTORY_STEP - prev_data:-HISTORY_STEP]

    x_prev  = np.arange(nweeks - HISTORY_STEP - prev_data, nweeks - HISTORY_STEP)
    x_input = np.arange(nweeks - HISTORY_STEP, nweeks)
    x_pred  = np.arange(nweeks, nweeks + PREDICTION_INTERVAL)
    x_tot   = list(x_prev) + list(x_input) + list(x_pred)
    weeks2plot = [tot_weeks[i] for i in x_tot]

    data_max   = np.max(input_arr)
    pred_max   = np.max(upper)
    prev_max   = np.max(prev_series) if len(prev_series) > 0 else 0

    # --- export CSV com todos os dados do gráfico ----------------------
    # Segmento 1: dados anteriores (vermelho)
    prev_weeks_list = [tot_weeks[i] for i in x_prev]
    df_prev = pd.DataFrame({
        'Week':              prev_weeks_list,
        'Segment':           'previous',
        'Smoothed_Cases':    prev_series.flatten(),
        'Mean_Prediction':   np.nan,
        'Upper_Bound':       np.nan,
        'Lower_Bound':       np.nan,
    })

    # Segmento 2: dados de entrada (azul)
    input_weeks_list = [tot_weeks[i] for i in x_input]
    df_input = pd.DataFrame({
        'Week':              input_weeks_list,
        'Segment':           'input',
        'Smoothed_Cases':    input_arr.flatten(),
        'Mean_Prediction':   np.nan,
        'Upper_Bound':       np.nan,
        'Lower_Bound':       np.nan,
    })

    # Segmento 3: predição (preto + banda cinza)
    df_pred = pd.DataFrame({
        'Week':              output_weeks,
        'Segment':           'prediction',
        'Smoothed_Cases':    np.nan,
        'Mean_Prediction':   mean_pred,
        'Upper_Bound':       upper,
        'Lower_Bound':       lower,
    })

    df_chart = pd.concat([df_prev, df_input, df_pred], ignore_index=True)
    chart_csv = os.path.join(output_path, f"{country}_chart_data.csv")
    df_chart.to_csv(chart_csv, index=False)
    print(f"Dados do gráfico exportados: {chart_csv}")

    fig, ax = plt.subplots(figsize=(16, 8))
    ax.plot(x_prev,  prev_series.flatten(), "r.-", label="Dados anteriores (não usados)")
    ax.plot(x_input, input_arr.flatten(),   "b.-", label="Dados de entrada")
    ax.fill_between(x_pred, lower, upper, color='gray', alpha=0.5, label="±2 desvios")
    ax.plot(x_pred, mean_pred, "k.-", label="Predição média")
    ax.set_xticks(x_tot)
    ax.set_xticklabels(weeks2plot, rotation=45)
    ax.set_ylim([0, 1.05 * max(pred_max, data_max, prev_max)])
    ax.set_xlabel("Semana epidemiológica", fontsize=12)
    ax.set_ylabel("Casos semanais de dengue", fontsize=12)
    taxa_media = float(np.mean(np.diff(mean_pred)))
    ax.set_title(
        f"{country}: taxa média predita = {taxa_media:.1f} casos/semana",
        fontsize=14
    )
    ax.legend()
    ax.grid(True)

    fig_name = (f"{country}_4weeks_prediction_since_week_"
                f"{tot_weeks[-PREDICTION_INTERVAL]}-{tot_weeks[-1]}.jpeg")
    fig.savefig(os.path.join(output_path, fig_name), format='jpeg', dpi=300)
    plt.close(fig)

    # --- salva CSV de predição -----------------------------------------
    pr = pd.DataFrame({
        'Upper_Bound':     upper,
        'Lower_Bound':     lower,
        'Mean_Prediction': mean_pred,
    })
    csv_out = os.path.join(output_path, f"{country}_dengue_pred_4plusweeks.csv")
    pr.to_csv(csv_out, index=False)
    print(f"Predição salva em: {csv_out}")

    print(f"\nTaxa semanal média predita: {taxa_media:.2f} casos/semana")


if __name__ == "__main__":
    main()
