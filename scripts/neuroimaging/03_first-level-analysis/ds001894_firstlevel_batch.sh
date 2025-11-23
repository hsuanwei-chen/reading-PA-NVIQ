#!/bin/bash
#SBATCH --mail-user=hsuan-wei.chen@vanderbilt.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name=ds001894_first-level
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8g
#SBATCH --time=3:00:00
#SBATCH --array=1-132
#SBATCH --output=/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/results/logs/ds001894_first-level_batch/output/first-level_%A_%a_log.txt
#SBATCH --error=/panfs/accrepfs.vampire/data/booth_lab/Isaac/01_project/reading-PA-NVIQ/results/logs/ds001894_first-level_batch/error/first-level_%A_%a_error.txt

# Load matlab environment
module load gcc/12.3
module load openmpi/4.1.5
module load matlab/2023a

# Set input paramters
cwd=$PWD
proj_dir=$(echo "${PWD%/*/*/*}")
PARTICPANTS_TXT=$proj_dir/scripts/neuroimaging/03_first-level-analysis/ds001894_participants_first-level.txt
# Get the subject ID for this job
mapfile -t PARTICPANTS < $PARTICPANTS_TXT
PARTICIPANT_LABEL=${PARTICPANTS[(${SLURM_ARRAY_TASK_ID} - 1)]}
    
# Print job info
echo "Array ID:" ${SLURM_ARRAY_TASK_ID}, "Subject ID:" ${PARTICIPANT_LABEL}

# Run SPM12 preprocessing pipeline
matlab -nodisplay -nodesktop -nosplash -r "ds001894_firstlevel_subject('${PARTICIPANT_LABEL}'); quit"