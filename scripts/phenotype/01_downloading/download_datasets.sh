#!/bin/bash

# Download phenotype and MRIQC data from OpenNeuro
# ------------------------------------------------
# Four datasets were download: 
#    - ds001486: https://openneuro.org/datasets/ds001486/versions/1.3.1
#    - ds001894: https://openneuro.org/datasets/ds001894/versions/1.4.2
#    - ds002236: https://openneuro.org/datasets/ds002236/versions/1.1.1
#    - ds006339: https://openneuro.org/datasets/ds006239/versions/1.0.3 
#
# Tutorial for downloading with datalad: https://dartbrains.org/content/Download_Data.html 

# Set directories
cwd=$PWD
proj_dir=$(echo "${PWD%/*/*/*}")

# Download phenotype data across datasets
# ---------------------------------------------
cd $proj_dir/data/phenotype/raw
echo "Downloading phenotype data..."

#  ds001486
echo "--ds001486..."
datalad install https://github.com/OpenNeuroDatasets/ds001486.git

# ds001894
echo "--ds001894..."
datalad install https://github.com/OpenNeuroDatasets/ds001894.git

# ds002236
echo "--ds002236..."
datalad install https://github.com/OpenNeuroDatasets/ds002236.git

# ds006239
echo "--ds006239..."
datalad install https://github.com/OpenNeuroDatasets/ds006239.git

# Download MRIQC data across datasets
# ---------------------------------------------
cd $proj_dir/data/neuroimaging/derivatives
echo "Downloading MRIQC data..."

#  ds001486
echo "--ds001486..."
datalad install https://github.com/OpenNeuroDerivatives/ds001486-mriqc.git

# ds001894
echo "--ds001894..."
datalad install https://github.com/OpenNeuroDerivatives/ds001894-mriqc.git

# ds002236
echo "--ds002236..."
datalad install https://github.com/OpenNeuroDerivatives/ds002236-mriqc.git

# ds006239
echo "--ds006239...not available at time of downloading-November 06, 2025"

# Return back to 01_downloading
cd $cwd
echo "Complete!"