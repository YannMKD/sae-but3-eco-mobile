import pandas as pd
import sqlite3
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

PATH_FINAL_CSV = 'spotify_data_preprocessed_final.csv'
PATH_POP_CSV = 'spotify_songs.csv'

try:
    df_final = pd.read_csv(PATH_FINAL_CSV)
    print(f"✅ Fichier chargé: {PATH_FINAL_CSV}")
except FileNotFoundError:
    print(f"❌ ERREUR: {PATH_FINAL_CSV} non trouvé.")
    exit()

try:
    df_pop = pd.read_csv(PATH_POP_CSV, usecols=['track_id', 'track_popularity'])
    print(f"✅ Fichier chargé: {PATH_POP_CSV}")
except FileNotFoundError:
    print(f"❌ ERREUR: {PATH_POP_CSV} non trouvé.")
    exit()

df = df_final.merge(df_pop, on='track_id', how='left')
print("✅ Fusion réussie")

df = df.drop_duplicates(subset='track_id')
print(f"✅ Doublons supprimés. Lignes: {len(df)}")

df['liked'] = 0

conn = sqlite3.connect('app_data.db')
df.to_sql('tracks', conn, if_exists='replace', index=False)
conn.close()

print("🚀 app_data.db créé avec succès")
