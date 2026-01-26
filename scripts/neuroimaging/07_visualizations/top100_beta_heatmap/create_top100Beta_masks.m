%% create top 100 masks
%
% This script aims to extract top 100 beta values from each participant's
% contrast map for voxels within the union map

%% Set input parameters
clear;clc

% Define contrast map and union ROIs
top_n = 100;
contrast = "con-NCFix";
con_map = 'con_0001.nii';
rois = {
    'leftIFG_n364_top1000_union-mask.nii'; 
    'leftTP_n364_top1000_union-mask.nii'; 
    'leftvOT_n364_top1000_union-mask.nii'
};

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
roi_dir  = fullfile(proj_dir, "results", "functional_ROIs", "top1000");

% Add directories to search path
addpath(genpath(util_dir));
addpath(spm_dir);

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'preregistration-amendment_participants.csv');

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Extract betas within union mask
disp("=====Job Start=====")
tic; 
count = 1;

for i = 1:length(subjects.participant_id)
    fprintf('%i. Extracting top %i betas from %s...\n', count, top_n, subjects.unique_id{i});
    
    for j = 1:length(rois)
        fprintf('---From %s ...', rois{j});

        % Define ROI
        roi_file = fullfile(roi_dir, rois{j});

        % Define subject's contrast map
        deweight_dir = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, 'analysis', 'deweight');
        con_map_file = fullfile(deweight_dir, con_map);

        % Create top_voxel directory
        output_dir = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, 'top_voxel');
        if ~exist(output_dir, "dir")
            mkdir(output_dir)
        end
    
        % Check contrast map exists
        if ~exist(con_map_file, "file")
            warning('Missing contrast map!')
            count = count + 1;
            continue
        end
 
        % Run extract_topVoxels
        output_prefix = sprintf('%s_%s_%s', subjects.unique_id{i}, contrast, rois{j}(1:end-4));
        extract_topBetas(con_map_file, roi_file, output_dir, output_prefix, top_n)
        
        fprintf('Done! \n')

    end
    
    count = count + 1;
    fprintf('\n')
    
end

disp("=====Job Complete=====")
toc;

