#!/bin/bash
#SBATCH --mail-user=hsuan-wei.chen@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name=ds006239_fmriprep
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16g
#SBATCH --time=6:00:00
#SBATCH --array=1-65
#SBATCH --output=/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/results/logs/ds006239_fmriprep_batch/output/fmriprep_%A_%a_log.txt
#SBATCH --error=/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/results/logs/ds006239_fmriprep_batch/error/fmriprep_%A_%a_error.txt

# Load fMRIPrep environment
module load fmriprep/25.1.1
export REQUESTS_CA_BUNDLE="/opt/conda/envs/fmriprep/lib/python3.10/site-packages/certifi/cacert.pem"

# Set input paramters
BIDS_DIR="/panfs/accrepfs.vampire/data/booth_lab/DHH/bids_1000s_ses-1/"
OUTPUT_DIR="/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/data/neuroimaging/derivatives/ds006239_fmriprep-qc/"
WORK_DIR="/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/_temp/fmriprep-qc/"
PARTICPANTS_TXT="/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/scripts/neuroimaging/02_preprocessing/fmriprep-qc/ds006239_participants_fmriprep.txt"
FS_LICENSE="/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/scripts/neuroimaging/02_preprocessing/fmriprep-qc/license.txt"
BIDS_FILTER="/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/scripts/neuroimaging/02_preprocessing/fmriprep-qc/ds006239_bids-filter.json"

# Get the subject ID for this job
mapfile -t PARTICPANTS < $PARTICPANTS_TXT
PARTICIPANT_LABEL=${PARTICPANTS[(${SLURM_ARRAY_TASK_ID} - 1)]}
TASK_ID="ReadPhon"

# Print job info
echo "Array ID:" ${SLURM_ARRAY_TASK_ID}, "Subject ID:" ${PARTICIPANT_LABEL}

# Run fMRIPrep
fmriprep "${BIDS_DIR}" "${OUTPUT_DIR}" \
  participant \
  --skip-bids-validation \
  --participant-label "${PARTICIPANT_LABEL}" \
  --task-id "${TASK_ID}" \
  --bids-filter-file "${BIDS_FILTER}" \
  --nprocs 8 \
  --output-spaces MNI152NLin2009cAsym:res-2 \
  --fs-license-file "${FS_LICENSE}" \
  --fs-no-reconall \
  --work-dir "${WORK_DIR}" \
  --write-graph \
  --verbose