%% check vOT's second level coverage
%
% This script aims to check how much of the vOT is covered at the second
% level 

%% Set input parameters
clear;clc

% Define directories
root_dir    = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir    = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir    = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir    = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir     = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
results_dir = fullfile(proj_dir, "results");

% Add directories to search path
addpath(genpath(util_dir));
addpath(spm_dir);

% Define paths to ROIs and mask
vOT_file     = fullfile(results_dir, "functional_ROIs", "top1000", "leftvOT_top1000_union-mask.nii");
mask_file    = fullfile(results_dir, "second-level-analysis", "one-sample-t", "non-conflicting_vs_fixation", "mask.nii");
heatmap_file = fullfile(results_dir, "check_secondLevelCoverage", "second-level_heatmap.nii");

%% Compute overlap
% Read in files
vOT_info = spm_vol(char(vOT_file));
vOT_img  = spm_read_vols(vOT_info);

mask_info = spm_vol(char(mask_file));
mask_img  = spm_read_vols(mask_info);

heatmap_info = spm_vol(char(heatmap_file));
heatmap_img  = spm_read_vols(heatmap_info);

% Compute overlap
overlap_img = vOT_img & mask_img;
overlap_idx = find(overlap_img == 1);

% Convert linear indices back to voxel coordinates
[x, y, z] = ind2sub(size(overlap_img), overlap_idx);
voxel_coord = [x, y, z, ones(length(x), 1)];

% Convert voxel coordinates back to MNI coordinates
% For more information: https://nipy.org/nibabel/coordinate_systems.html
affine = mask_info.mat;
mni_coord = affine * voxel_coord';
overlap_mni = mni_coord(1:3, :)';

% Extract MNI coordinates for voT
vOT_mni = extract_MNIcoordinates(vOT_file);

% Add logical vector showing which voxels overlap or are missing
vOT_mni(:, 4) = ismember(vOT_mni, overlap_mni, "rows");

%% Compute missing voxels
missing_img = vOT_img &~ mask_img;
missing_idx = find(missing_img == 1);

% Convert linear indices back to voxel coordinates
[x, y, z] = ind2sub(size(missing_img), missing_idx);
voxel_coord = [x, y, z, ones(length(x), 1)];

% Convert voxel coordinates back to MNI coordinates
% For more information: https://nipy.org/nibabel/coordinate_systems.html
affine = mask_info.mat;
mni_coord = affine * voxel_coord';
missing_mni = mni_coord(1:3, :)';

% Add logical vector showing which voxels overlap or are missing
vOT_mni(:, 5) = ismember(vOT_mni(:, 1:3), missing_mni, "rows");

idx = vOT_mni(:, 5) == 1;
vOT_mni(idx, 6) = heatmap_img(missing_idx);

% Save results as csv
output_file = fullfile(results_dir, "check_secondLevelCoverage", "vOT_second-level-coverage.csv");
output_tbl = array2table(vOT_mni);
output_tbl.Properties.VariableNames = [{'MNI_X', 'MNI_Y', 'MNI_Z', 'Overlap', 'Missing', 'Num_participants'}];
writetable(output_tbl, output_file);

