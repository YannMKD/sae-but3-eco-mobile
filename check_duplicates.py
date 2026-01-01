import pandas as pd
import os

# Set working directory to script location
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

# Check for duplicates in the CSVs
df_final = pd.read_csv('spotify_data_preprocessed_final.csv')
print(f"Total rows in final CSV: {len(df_final)}")
print(f"Unique track_ids in final CSV: {df_final['track_id'].nunique()}")
print(f"Duplicates in final CSV: {df_final.duplicated(subset='track_id').sum()}")

df_songs = pd.read_csv('spotify_songs.csv')
print(f"Total rows in songs CSV: {len(df_songs)}")
print(f"Unique track_ids in songs CSV: {df_songs['track_id'].nunique()}")
print(f"Duplicates in songs CSV: {df_songs.duplicated(subset='track_id').sum()}")

# After merge
merged = df_final.merge(df_songs[['track_id', 'track_popularity']], on='track_id', how='left')
print(f"Total rows after merge: {len(merged)}")
print(f"Unique track_ids after merge: {merged['track_id'].nunique()}")
print(f"Duplicates after merge: {merged.duplicated(subset='track_id').sum()}")
