import pandas as pd
import glob
import os

pasta = os.path.expanduser("~/Scientific_Initiation_Dashboard/Dashboard/input_old/predictions/DATA_03.06.2026_19h_MODEL_03.06.2026_19h/DATA_03.06.2026_19h_MODEL_03.06.2026_19h/")

arquivos = glob.glob(pasta + "*_dengue_pred_4plusweeks.csv")

semanas = ['2026.18', '2026.19', '2026.20', '2026.21']

dfs = []
for arquivo in sorted(arquivos):
    estado = os.path.basename(arquivo).split("_")[0]
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
