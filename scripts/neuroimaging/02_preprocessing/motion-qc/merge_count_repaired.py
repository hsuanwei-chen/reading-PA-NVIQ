from pathlib import Path
import pandas as pd

# Set input parameters
proj_dir = Path(__file__).resolve().parents[4]
data_dir = proj_dir / "results" / "fMRI_count_repaired"

count_repaired_csv = [
    data_dir / "ds001486_count_repaired.csv", 
    data_dir / "ds001894_count_repaired.csv", 
    data_dir / "ds002236_count_repaired.csv",
    data_dir / "ds006239_count_repaired.csv"
]

output_csv = data_dir / "merged_count_repaired.csv"

# Read and concatenate
df = pd.concat(
    [pd.read_csv(f) for f in count_repaired_csv], 
    ignore_index = True
)

# Save merged result
df.to_csv(output_csv, index = False)
print("Count repaired files merged successfully.")