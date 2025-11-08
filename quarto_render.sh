#!/bin/bash

# Render QMD file and save it in results/report folder
# ------------------------------------------------
#
# Set directories
proj_dir=$PWD
f_src=$proj_dir/scripts/phenotype/02_preprocessing/ds001486_create-dataset.qmd
f_base=$(basename "$f_src" .qmd)
f_dest=$proj_dir/results/reports/$f_base.html

# Render file
quarto render $f_src
mv ${f_src%.*}.html $f_dest
open $f_dest