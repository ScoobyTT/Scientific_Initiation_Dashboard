import pandas as pd
import os
import glob

TRAINING_DIR = "03.06.2026_19h_training_data"
PRED_FILE = "predicoes_2026/predicoes_todos_estados.csv"
OUTPUT = "predicoes_2026/plot1_pred_new.csv"

# Ler histórico de cada estado a partir dos CSVs individuais
historico_dfs = []
for csv_path in glob.glob(os.path.join(TRAINING_DIR, "*_time_series_*.csv")):
    estado = os.path.basename(csv_path).split("_")[0]
    df = pd.read_csv(csv_path)
    df.columns = [c.strip() for c in df.columns]
    df['Date'] = df['Date'].astype(str).str.replace("'", "").str.strip()
    df['abbrev_state'] = estado
    df = df.rename(columns={'Smoothed Dengue Cases': 'cases'})
    df = df[['Date', 'abbrev_state', 'cases']].copy()
    historico_dfs.append(df)

historico = pd.concat(historico_dfs, ignore_index=True)

# Quando há dois arquivos por estado (ex: AL), pegar o mais longo
historico = historico.sort_values(['abbrev_state', 'Date'])
historico = historico.drop_duplicates(subset=['abbrev_state', 'Date'], keep='last')

# Marcar source
dfs = []
for estado, grupo in historico.groupby('abbrev_state'):
    grupo = grupo.reset_index(drop=True)
    n = len(grupo)
    corte = max(0, n - 13)
    grupo['source'] = 'previous_not_used_data'
    grupo.loc[corte:, 'source'] = 'used_input_data'
    dfs.append(grupo)

historico_final = pd.concat(dfs)
historico_final = historico_final.rename(columns={'Date': 'week'})
historico_final['lower_bound'] = None
historico_final['upper_bound'] = None
historico_final = historico_final[['week', 'abbrev_state', 'cases', 'lower_bound', 'upper_bound', 'source']]

# Ler predições
pred_raw = pd.read_csv(PRED_FILE)
pred_raw = pred_raw.rename(columns={
    'Mean_Prediction': 'cases',
    'Lower_Bound': 'lower_bound',
    'Upper_Bound': 'upper_bound'
})
pred_raw['source'] = 'predicted'
pred_raw = pred_raw[['week', 'abbrev_state', 'cases', 'lower_bound', 'upper_bound', 'source']]

# Juntar e salvar
resultado = pd.concat([historico_final, pred_raw], ignore_index=True)
# Remove duplicatas: predicted tem prioridade sobre used_input_data
resultado['week'] = resultado['week'].astype(float)
resultado = resultado.sort_values('source', key=lambda x: x.map({'predicted': 0, 'used_input_data': 1, 'previous_not_used_data': 2}))
resultado = resultado.drop_duplicates(subset=['week', 'abbrev_state'], keep='first')
resultado = resultado.sort_values(['abbrev_state', 'week'])

resultado.to_csv(OUTPUT, index=False)
print(f"Salvo em {OUTPUT}")
print(resultado[resultado['abbrev_state'] == 'SP'].tail(10))
