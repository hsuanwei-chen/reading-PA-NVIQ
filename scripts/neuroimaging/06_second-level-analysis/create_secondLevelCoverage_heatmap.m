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

% Define mask image name
mask_fname = 'mask.nii';

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Create brain coverage heatmap
count = 1;
for i = 1:length(subjects.unique_id)
    if i == 1
        fprintf('%i. Loading mask file for %s ... ', count, subjects.unique_id{i}); 
        
        mask_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', mask_fname);
        mask_info = spm_vol(char(mask_file));
        mask_img  = spm_read_vols(mask_info);

        heatmap_img = zeros(size(mask_img));

        heatmap_img = heatmap_img + mask_img;

        fprintf('Done\n');
        count = count + 1;
    else
        fprintf('%i. Loading mask file for %s ... ', count, subjects.unique_id{i}); 
        
        mask_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', mask_fname);
        mask_info = spm_vol(char(mask_file));
        mask_img  = spm_read_vols(mask_info);

        heatmap_img = heatmap_img + mask_img;
        
        fprintf('Done\n');
        count = count + 1;
    end
end

% Save coverage heatmap
% Set mask header information
heatmap_hdr = mask_info;
heatmap_hdr.fname = char(fullfile(proj_dir, "results", "check_secondLevelCoverage", "second-level_heatmap.nii"));
heatmap_hdr.dt = [16, 0];
heatmap_hdr.descrip = sprintf('Coverage heatmap: each voxel represents number of participants with data in that voxel');

% Write mask into 3D image
spm_write_vol(heatmap_hdr, heatmap_img);

t_info = spm_vol(heatmap_hdr.fname);
t_img = spm_read_vols(t_info);