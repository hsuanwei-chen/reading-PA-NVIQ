from pathlib import Path
import pandas as pd

# Set input parameters
proj_dir = Path(__file__).resolve().parents[4]
participants_csv = proj_dir / "data" / "phenotype" / "merged" / "merged_participants_motionQC.csv"

# Read in csv file
participants_df = pd.read_csv(participants_csv)

# Extract ds001486 participants who passed motion QC
ds001486_df = participants_df[participants_df["dataset"] == "ds001486"]
ds001486_df = ds001486_df[ds001486_df["exclude"].isna()]
ds001486_df["participant_label"] = ds001486_df["participant_id"].astype(str).str[-3:]
ds001486_df["participant_label"].to_csv(
    "ds001486_participants_fmriprep.txt", 
    index = False, header = False
)

# Extract ds001894 participants who passed motion QC
ds001894_df = participants_df[participants_df["dataset"] == "ds001894"]
ds001894_df = ds001894_df[ds001894_df["exclude"].isna()]
ds001894_df["participant_label"] = ds001894_df["participant_id"].astype(str).str[-3:]
ds001894_df["participant_label"].to_csv(
    "ds001894_participants_fmriprep.txt", 
    index = False, header = False
)

# Extract ds002236 participants who passed motion QC
ds002236_df = participants_df[participants_df["dataset"] == "ds002236"]
ds002236_df = ds002236_df[ds002236_df["exclude"].isna()]
ds002236_df["participant_label"] = ds002236_df["participant_id"].astype(str).str[-2:]
ds002236_df["participant_label"].to_csv(
    "ds002236_participants_fmriprep.txt", 
    index = False, header = False
)
# Extract ds006239 particiaptns who passed motion QC
ds006239_df = participants_df[participants_df["dataset"] == "ds006239"]
ds006239_df = ds006239_df[ds006239_df["exclude"].isna()]
ds006239_df["participant_label"] = ds006239_df["participant_id"].astype(str).str[-4:]
ds006239_df["participant_label"].to_csv(
    "ds006239_participants_fmriprep.txt", 
    index = False, header = False
)