import pandas as pd
import glob
import os

base = os.path.expanduser("~/Scientific_Initiation_Dashboard/Dashboard/DENGUE_PIPELINE 2 DEPLOY EMPTY (1)(1)/DENGUE_PIPELINE 2 DEPLOY EMPTY/results/predictions/")
pastas = sorted(glob.glob(base + "DATA_*_MODEL_*/"))
pasta = pastas[-1]  # pega a mais recente
print(f"Usando pasta: {pasta}")
arquivos = glob.glob(pasta + "*_dengue_pred_4plusweeks.csv")

# pega o chart_data do primeiro arquivo encontrado pra extrair as semanas
chart_files = glob.glob(pasta + "*_chart_data.csv")
df_chart = pd.read_csv(chart_files[0])
semanas = df_chart[df_chart['Segment'] == 'prediction']['Week'].tolist()

dfs = []
for arquivo in sorted(arquivos):
    estado = os.path.basename(arquivo).replace("_dengue_pred_4plusweeks.csv", "")
    df = pd.read_csv(arquivo)
    df['abbrev_state'] = estado
    df['week'] = semanas
    dfs.append(df)

resultado = pd.concat(dfs, ignore_index=True)
resultado = resultado[['week', 'abbrev_state', 'Mean_Prediction', 'Lower_Bound', 'Upper_Bound']]
resultado = resultado.sort_values(['abbrev_state', 'week'])

output = os.path.expanduser("~/Scientific_Initiation_Dashboard/Dashboard/input_old/predicoes_todos_estados.csv")
resultado.to_csv(output, index=False)

print(f"Salvo em {output}")
print(resultado.head(10))
print(f"Total de linhas: {len(resultado)}")
