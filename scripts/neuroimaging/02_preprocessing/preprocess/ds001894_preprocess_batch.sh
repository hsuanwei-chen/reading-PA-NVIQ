#!/bin/bash
#SBATCH --mail-user=hsuan-wei.chen@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name=ds001894_preprocess
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8g
#SBATCH --time=6:00:00
#SBATCH --array=1-132
#SBATCH --output=/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/results/logs/ds001894_preprocess_batch/output/preprocess_%A_%a_log.txt
#SBATCH --error=/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/results/logs/ds001894_preprocess_batch/error/preprocess_%A_%a_error.txt

# Load matlab environment
module load gcc/12.3
module load openmpi/4.1.5
module load matlab/2023a

# Set input paramters
cwd=$PWD
proj_dir=$(echo "${PWD%/*/*/*/*}")
PARTICPANTS_TXT=$proj_dir/scripts/neuroimaging/02_preprocessing/preprocess/ds001894_participants_preprocess.txt

# Get the subject ID for this job
mapfile -t PARTICPANTS < $PARTICPANTS_TXT
PARTICIPANT_LABEL=${PARTICPANTS[(${SLURM_ARRAY_TASK_ID} - 1)]}
    
# Print job info
echo "Array ID:" ${SLURM_ARRAY_TASK_ID}, "Subject ID:" ${PARTICIPANT_LABEL}

# Run SPM12 preprocessing pipeline
matlab -nodisplay -nodesktop -nosplash -r "ds001894_preprocess_subject('${PARTICIPANT_LABEL}'); quit"