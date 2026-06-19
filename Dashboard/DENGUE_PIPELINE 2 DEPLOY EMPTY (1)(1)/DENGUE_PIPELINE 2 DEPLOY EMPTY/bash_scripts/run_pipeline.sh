#!/bin/bash
# =============================================================================
# run_pipeline.sh — Executa o pipeline completo de predição de dengue
# Preprocessamento → Treinamento → Predição
#
# Uso:
#   bash run_pipeline.sh <diretório_de_dados> <arquivo_csv>
#
# Exemplo:
#   bash run_pipeline.sh /caminho/para/dados dengue_dataset.csv
#
# O script deve ser chamado a partir do diretório bash_scripts/
# (igual aos scripts individuais existentes), pois os Python scripts
# usam caminhos relativos ../apps/ e ../results/
# =============================================================================

set -euo pipefail   # para imediatamente em qualquer erro

# ---------------------------------------------------------------------------
# Verifica argumentos
# ---------------------------------------------------------------------------

if [ "$#" -ne 3 ]; then
    echo "Uso: $0 <diretório_de_dados> <arquivo_csv> <sinan_calendario.txt>"
    echo "Exemplo: $0 /Users/vagner/data dengue_dataset.csv /Users/vagner/data/sinan_calendario.txt"
    exit 1
fi

DATA_DIR="$1"
DATA_FILE="$2"
CALENDAR_FILE="$3"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"  # diretório absoluto deste script
APPS_DIR="${SCRIPT_DIR}/../apps"
LOG_FILE="${SCRIPT_DIR}/pipeline_output.log"

# ---------------------------------------------------------------------------
# Inicializa log
# ---------------------------------------------------------------------------

[ -e "$LOG_FILE" ] && rm "$LOG_FILE"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "========================================================"
log "  PIPELINE DE PREDIÇÃO DE DENGUE"
log "  $(date '+%d/%m/%Y %H:%M:%S')"
log "========================================================"
log "Diretório de dados : ${DATA_DIR}"
log "Arquivo CSV        : ${DATA_FILE}"
log "Calendário SINAN   : ${CALENDAR_FILE}"
log "Diretório de apps  : ${APPS_DIR}"
log ""

# ---------------------------------------------------------------------------
# Verifica que o calendário SINAN existe
# ---------------------------------------------------------------------------

if [ ! -f "$CALENDAR_FILE" ]; then
    log "ERRO: arquivo de calendário SINAN '${CALENDAR_FILE}' não encontrado."
    exit 1
fi

# ---------------------------------------------------------------------------
# Verifica que os scripts Python existem
# ---------------------------------------------------------------------------

for script in preprocessor_v3.py trainer_v3.py predictor_v3.py; do
    if [ ! -f "${APPS_DIR}/${script}" ]; then
        log "ERRO: ${APPS_DIR}/${script} não encontrado."
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Verifica que o CSV de entrada existe
# ---------------------------------------------------------------------------

if [ ! -f "${DATA_DIR}/${DATA_FILE}" ]; then
    log "ERRO: arquivo '${DATA_DIR}/${DATA_FILE}' não encontrado."
    exit 1
fi

# ---------------------------------------------------------------------------
# ETAPA 1: PREPROCESSAMENTO
# ---------------------------------------------------------------------------

log "--------------------------------------------------------"
log "ETAPA 1/3 — PREPROCESSAMENTO"
log "--------------------------------------------------------"

python3 "${APPS_DIR}/preprocessor_v3.py" \
    --directory "${DATA_DIR}" \
    --file      "${DATA_FILE}" \
    2>&1 | tee -a "$LOG_FILE"

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    log "ERRO: preprocessamento falhou. Pipeline interrompido."
    exit 1
fi

log ""
log "Preprocessamento concluído."

# ---------------------------------------------------------------------------
# Descobre o diretório de training_data gerado pelo preprocessador
# O preprocessador cria: <DATA_DIR>/<DD.MM.YYYY_HHh>_training_data/
# ---------------------------------------------------------------------------

TRAINING_DATA_DIR=$(ls -dt "${DATA_DIR}"/*_training_data/ 2>/dev/null | head -1)

if [ -z "$TRAINING_DATA_DIR" ]; then
    log "ERRO: diretório training_data não encontrado em ${DATA_DIR}."
    exit 1
fi

# Remove barra final se houver
TRAINING_DATA_DIR="${TRAINING_DATA_DIR%/}"
log "Diretório de dados de treinamento: ${TRAINING_DATA_DIR}"

# Lista de países gerada pelo preprocessador
COUNTRIES_FILE="${TRAINING_DATA_DIR}/country_list.txt"

if [ ! -f "$COUNTRIES_FILE" ]; then
    log "ERRO: country_list.txt não encontrado em ${TRAINING_DATA_DIR}."
    exit 1
fi

NCTRY=$(wc -l < "$COUNTRIES_FILE" | tr -d ' ')
log "Países a processar: ${NCTRY}"
log ""

# ---------------------------------------------------------------------------
# ETAPA 2: TREINAMENTO (um modelo por país)
# ---------------------------------------------------------------------------

log "--------------------------------------------------------"
log "ETAPA 2/3 — TREINAMENTO"
log "--------------------------------------------------------"

TRAIN_FAILURES=0

while IFS= read -r country; do
    [ -z "$country" ] && continue   # pula linhas vazias
    log "  Treinando: ${country}"
    python3 "${APPS_DIR}/trainer_v3.py" \
        --directory "${TRAINING_DATA_DIR}" \
        --country   "${country}" \
        2>&1 | tee -a "$LOG_FILE"

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        log "  AVISO: treinamento falhou para ${country}. Continuando com os demais."
        TRAIN_FAILURES=$((TRAIN_FAILURES + 1))
    else
        log "  OK: ${country}"
    fi
    log ""
done < "$COUNTRIES_FILE"

if [ "$TRAIN_FAILURES" -gt 0 ]; then
    log "AVISO: ${TRAIN_FAILURES} país(es) falharam no treinamento."
fi

# ---------------------------------------------------------------------------
# Descobre o diretório de modelos gerado pelo trainer
# O trainer cria: ../results/models/<DD.MM.YYYY_HHh>/
# O run_code é extraído do nome do TRAINING_DATA_DIR
# ---------------------------------------------------------------------------

RUN_CODE=$(basename "$TRAINING_DATA_DIR" | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{4}_[0-9]{2}h')

if [ -z "$RUN_CODE" ]; then
    log "ERRO: não foi possível extrair run_code de '${TRAINING_DATA_DIR}'."
    exit 1
fi

MODEL_DIR="${SCRIPT_DIR}/../results/models/${RUN_CODE}"

if [ ! -d "$MODEL_DIR" ]; then
    log "ERRO: diretório de modelos não encontrado: ${MODEL_DIR}"
    exit 1
fi

log "Diretório de modelos: ${MODEL_DIR}"
log ""

# ---------------------------------------------------------------------------
# ETAPA 3: PREDIÇÃO (um por país)
# ---------------------------------------------------------------------------

log "--------------------------------------------------------"
log "ETAPA 3/3 — PREDIÇÃO"
log "--------------------------------------------------------"

PRED_FAILURES=0

while IFS= read -r country; do
    [ -z "$country" ] && continue
    log "  Predizendo: ${country}"
    python3 "${APPS_DIR}/predictor_v3.py" \
        --data_directory  "${TRAINING_DATA_DIR}" \
        --model_directory "${MODEL_DIR}" \
        --country         "${country}" \
        --calendar        "${CALENDAR_FILE}" \
        2>&1 | tee -a "$LOG_FILE"

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        log "  AVISO: predição falhou para ${country}."
        PRED_FAILURES=$((PRED_FAILURES + 1))
    else
        log "  OK: ${country}"
    fi
    log ""
done < "$COUNTRIES_FILE"

if [ "$PRED_FAILURES" -gt 0 ]; then
    log "AVISO: ${PRED_FAILURES} país(es) falharam na predição."
fi

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------

log "========================================================"
log "  PIPELINE CONCLUÍDO — $(date '+%d/%m/%Y %H:%M:%S')"
log "  Falhas no treinamento : ${TRAIN_FAILURES}"
log "  Falhas na predição    : ${PRED_FAILURES}"
log "  Log completo          : ${LOG_FILE}"
log "========================================================"