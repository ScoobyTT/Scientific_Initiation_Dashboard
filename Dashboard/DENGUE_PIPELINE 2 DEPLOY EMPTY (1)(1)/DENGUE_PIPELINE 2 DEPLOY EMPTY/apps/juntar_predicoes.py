import glob, pandas as pd
import os

SIGLAS = {
    "Acre": "AC", "Alagoas": "AL", "Amapa": "AP", "Amazonas": "AM",
    "Bahia": "BA", "Ceara": "CE", "Distrito Federal": "DF",
    "Espirito Santo": "ES", "Goias": "GO", "Maranhao": "MA",
    "Mato Grosso": "MT", "Mato Grosso do Sul": "MS", "Minas Gerais": "MG",
    "Para": "PA", "Paraiba": "PB", "Parana": "PR", "Pernambuco": "PE",
    "Piaui": "PI", "Rio de Janeiro": "RJ", "Rio Grande do Norte": "RN",
    "Rio Grande do Sul": "RS", "Rondonia": "RO", "Roraima": "RR",
    "Santa Catarina": "SC", "Sao Paulo": "SP", "Sergipe": "SE",
    "Tocantins": "TO","Goais": "GO","Brasil": "BR"
}


dfs = []
for f in glob.glob("../results/predictions/*/*_chart_data.csv"):
    state = os.path.basename(f).split("_")[0]
    sigla = SIGLAS[state]

    df = pd.read_csv(f)
    df["abbrev_state"] = sigla
    dfs.append(df)

pd.concat(dfs).to_csv("todas_predicoes.csv", index=False)
