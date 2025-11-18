#!/bin/bash
#SBATCH --mail-user=hsuan-wei.chen@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --ntasks=1
#SBATCH --time=2:00:00
#SBATCH --mem=8G
#SBATCH --array=1-89%10
#SBATCH --output=output_preprocess_sub_ds00DHH_slurm/ds00DHH_slurm_%A_%a.out

# Specify subject list
subject_list="/panfs/accrepfs.vampire/data/booth_lab/Isaac/reading-PA-NVIQ/preproc/ds00DHH/subjects_ds00DHH.csv"

# Read in subject list
subjects=($(tail -n +2 "$subject_list" | cut -d',' -f1))

# Get the subject ID for this job
subject_id=${subjects[$SLURM_ARRAY_TASK_ID -1]}

# Run preprocessing for each subject
module load legacy_load
legacy_load "module load GCC/5.4.0-2.26; module load MATLAB/2018b; matlab -nodisplay -nodesktop -nosplash -r \"preprocess_sub_ds00DHH('$subject_id'); quit\""
