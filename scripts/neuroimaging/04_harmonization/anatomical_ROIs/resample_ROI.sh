#!/bin/bash

# resample_ROI
# ------------------------------------------------
# This script will resample the ROIs created from the AAL atlas (dims: 91 x 109 x 91) 
# to match SPM12's contrast map (dims: 79 x 95 x 79)

# Load FSL environment
module load fsl/6.0.7.18

# Set directories
cwd=$PWD
proj_dir=$(echo "${PWD%/*/*/*/*}")

# Set input parameters
REFERENCE=$proj_dir/results/anatomical_ROIs/templates/mask.nii

left_IFG=$proj_dir/results/anatomical_ROIs/AAL_atlas/left_IFG-Oper-Tri.nii
r_left_IFG=$proj_dir/results/anatomical_ROIs/resampled_ROIs/r_leftIFG.nii

left_TP=$proj_dir/results/anatomical_ROIs/trimmed_ROIs/left_TP.nii
r_left_TP=$proj_dir/results/anatomical_ROIs/resampled_ROIs/r_leftTP.nii

left_vOT=$proj_dir/results/anatomical_ROIs/trimmed_ROIs/left_vOT.nii
r_left_vOT=$proj_dir/results/anatomical_ROIs/resampled_ROIs/r_leftvOT.nii

echo "Resampling ROIs ..."

# Resample Left IFG-Oper-Tri
echo "--Left IFG-Oper-Tri ..."
flirt \
   -in $left_IFG \
   -ref $REFERENCE \
   -applyxfm \
   -usesqform \
   -out $r_left_IFG

gunzip $r_left_IFG

# Resample Left TP
echo "--Left TP ..."
flirt \
   -in $left_TP \
   -ref $REFERENCE \
   -applyxfm \
   -usesqform \
   -out $r_left_TP

gunzip $r_left_TP

# Resample Left vOT
echo "--Left vOT ..."
flirt \
   -in $left_vOT \
   -ref $REFERENCE \
   -applyxfm \
   -usesqform \
   -out $r_left_vOT

gunzip $r_left_vOT

echo "Complete!"