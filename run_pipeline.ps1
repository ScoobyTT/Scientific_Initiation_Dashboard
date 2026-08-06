# Diretório onde este script está localizado
$DASHBOARD_DIR = $PSScriptRoot

# Diretório de logs
$LOG_DIR = Join-Path $DASHBOARD_DIR "logs"

# Nome do arquivo de log
$LOG_FILE = Join-Path $LOG_DIR ("pipeline_{0}.log" -f (Get-Date -Format "yyyy-MM-dd"))

# Nome da imagem Docker
$IMAGE_NAME = "dengue-pipeline"

# Cria a pasta de logs se não existir
New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null

Add-Content $LOG_FILE "========================================"
Add-Content $LOG_FILE "Início: $(Get-Date)"
Add-Content $LOG_FILE "========================================"

# Build da imagem
docker build -t $IMAGE_NAME $DASHBOARD_DIR *> $LOG_FILE

if ($LASTEXITCODE -ne 0) {
    Add-Content $LOG_FILE "[ERRO] Falha no docker build. Abortando."
    exit 1
}

# Executa o container montando a pasta input
docker run --rm `
    -v "${DASHBOARD_DIR}/input:/data/input" `
    $IMAGE_NAME *>> $LOG_FILE

$EXIT_CODE = $LASTEXITCODE

Add-Content $LOG_FILE "----------------------------------------"

if ($EXIT_CODE -eq 0) {
    Add-Content $LOG_FILE "Fim: $(Get-Date) — SUCESSO"
}
else {
    Add-Content $LOG_FILE "Fim: $(Get-Date) — FALHOU (código $EXIT_CODE)"
}

Add-Content $LOG_FILE "========================================"

exit $EXIT_CODE