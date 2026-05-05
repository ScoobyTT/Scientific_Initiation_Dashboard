#!/bin/bash

DASHBOARD_DIR="/home/christian/Scientific_Initiation_Dashboard/Dashboard"
LOG_DIR="/home/christian/Scientific_Initiation_Dashboard/logs"
LOG_FILE="${LOG_DIR}/pipeline_$(date +%Y-%m-%d).log"
IMAGE_NAME="dengue-pipeline"

mkdir -p "$LOG_DIR"

echo "========================================" >> "$LOG_FILE"
echo "Início: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Build da imagem (só rebuilda se o Dockerfile mudou)
docker build -t "$IMAGE_NAME" "$DASHBOARD_DIR" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "[ERRO] Falha no docker build. Abortando." >> "$LOG_FILE"
    exit 1
fi

# Roda o container montando a pasta input como volume
docker run --rm \
    -v "${DASHBOARD_DIR}/input:/data/input" \
    "$IMAGE_NAME" >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

echo "----------------------------------------" >> "$LOG_FILE"
if [ $EXIT_CODE -eq 0 ]; then
    echo "Fim: $(date) — SUCESSO" >> "$LOG_FILE"
else
    echo "Fim: $(date) — FALHOU (código $EXIT_CODE)" >> "$LOG_FILE"
fi
echo "========================================" >> "$LOG_FILE"

exit $EXIT_CODE
