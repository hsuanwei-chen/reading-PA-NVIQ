%% check second level brain coverage
%
% This script aims to create a mask that shows voxels where all
% participants have data for in their first level contrast maps

%% Set input parameters
clear;clc

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 

% Add directories to search path
addpath(genpath(util_dir));
addpath(genpath(spm_dir));

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'preregistration_participants.csv');

% Define contrast image name
con_fname = 'con_0001.nii';

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Check second-level mask
mask_file = fullfile(proj_dir, "results", "second-level-analysis", "one-sample-t", "non-conflicting_vs_fixation", "mask.nii");
mask_info = spm_vol(char(mask_file));
mask_img  = spm_read_vols(mask_info);

% Report number of voxels
mask_nvoxel = sum(~isnan(mask_img) & mask_img ~= 0, "all");
fprintf('%i voxels found in the second-level mask\n', mask_nvoxel);

%% Double check brain covearge by hand
count = 1;
for i = 1:length(subjects.unique_id)
    if i == 1
        fprintf('%i. Loading contrast file for %s ... ', count, subjects.unique_id{i}); 
        
        con_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', con_fname);
        con_info = spm_vol(char(con_file));
        
        dims = con_info.dim;
        group_mask = true(dims);

        con_map = spm_read_vols(con_info);
        valid_voxels = ~isnan(con_map) & con_map ~= 0;
        
        group_mask = group_mask & valid_voxels;

        fprintf('Done\n');
        count = count + 1;
    else
        fprintf('%i. Loading contrast file for %s ... ', count, subjects.unique_id{i});
        
        con_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', con_fname);
        con_info = spm_vol(char(con_file));

        con_map = spm_read_vols(con_info);
        valid_voxels = ~isnan(con_map) & con_map ~= 0;
        
        group_mask = group_mask & valid_voxels;
        
        fprintf('Done\n');
        count = count + 1;
    end
end

% Report number of voxels
group_mask_nvoxel = sum(group_mask, "all");
fprintf('%i voxels found in the group mask\n', group_mask_nvoxel);

% Save union mask
% Set mask header information
group_mask_hdr = con_info;
group_mask_hdr.fname = char(fullfile(proj_dir, "results", "check_secondLevelCoverage", "second-level_group-mask.nii"));
group_mask_hdr.descrip = sprintf('Mask: voxels with data from all subjects');

% Write mask into 3D image
spm_write_vol(group_mask_hdr, group_mask);
