cat > ../../../input_old/baixar_dengue.py << 'EOF'
from pysus.online_data.SINAN import download
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))

estados = [
    'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA',
    'MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN',
    'RS','RO','RR','SC','SP','SE','TO'
]

for uf in estados:
    print(f"Baixando {uf} 2024...")
    try:
        df = download("DENG", 2024, uf)
        df.to_csv(f"dengue_sinan_2024/DENG_{uf}_2024.csv", index=False)
        print(f"  {uf} salvo com {len(df)} registros")
    except Exception as e:
        print(f"  ERRO em {uf}: {e}")

print("Download concluído!")
EOF