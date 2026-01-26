%% check second level brain coverage
%
% This script aims to create a mask that shows voxels where all
% participants have data for in their first level contrast maps

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

% Define merged_participants.csv
subj_csv = fullfile(results_dir, "check_secondLevelCoverage", "voxel_525226.csv");

% Define mask image name
mask_fname = 'mask.nii';

% Define path to ROI
vOT_file = fullfile(results_dir, "functional_ROIs", "top1000", "leftvOT_top1000_union-mask.nii");

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Double check brain covearge by hand
disp("=====Job Start=====")
tic;
count = 1;
for i = 1:length(subjects.unique_id)
    if i == 1
        fprintf('%i. Loading mask file for %s ... ', count, subjects.unique_id{i}); 
        
        mask_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', mask_fname);
        mask_info = spm_vol(char(mask_file));
        mask_img  = spm_read_vols(mask_info);
        
        dims = mask_info.dim;
        group_mask = true(dims);

        valid_voxels = ~isnan(mask_img) & mask_img ~= 0;
        
        group_mask = group_mask & valid_voxels;

        fprintf('Done\n');
        count = count + 1;
    else
        fprintf('%i. Loading mask file for %s ... ', count, subjects.unique_id{i});
        
        mask_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', mask_fname);
        mask_info = spm_vol(char(mask_file));
        mask_img  = spm_read_vols(mask_info);

        valid_voxels = ~isnan(mask_img) & mask_img ~= 0;
        
        group_mask = group_mask & valid_voxels;
        
        fprintf('Done\n');
        count = count + 1;
    end
end

disp("=====Job Complete=====")
toc

% Report number of voxels
group_mask_nvoxel = sum(group_mask, "all");
fprintf('%i voxels found in the group mask\n', group_mask_nvoxel);

% Save union mask
% Set mask header information
group_mask_hdr = mask_info;
group_mask_hdr.fname = char(fullfile(results_dir, "check_secondLevelCoverage", "second-level_group-mask_voxel525226.nii"));
group_mask_hdr.descrip = sprintf('Mask: voxels with data from all subjects');

% Write mask into 3D image
spm_write_vol(group_mask_hdr, group_mask);

%% Compute overlap
% Read in files
vOT_info = spm_vol(char(vOT_file));
vOT_img  = spm_read_vols(vOT_info);

group_mask_info = spm_vol(char(group_mask_hdr.fname));
mask_img  = spm_read_vols(group_mask_info);

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

% Save results as csv
output_file = fullfile(results_dir, "check_secondLevelCoverage", "vOT_second-level-coverage_voxel525226.csv");
output_tbl = array2table(vOT_mni);
output_tbl.Properties.VariableNames = [{'MNI_X', 'MNI_Y', 'MNI_Z', 'Overlap', 'Missing'}];
writetable(output_tbl, output_file);
