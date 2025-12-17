%% ds006239_extract_topVoxels
%
% This script aims to extract the top N most activated voxels in a 
% participant's first-level t-statistic map

%% Set input parameters
clear;clc

% Define dataset, top number of voxels
dataset = 'ds006239';
session = 'ses-1';
top_n = 1000;
contrast = "con-NCFix";
t_map = 'spmT_0001.nii';
rois = {'r_leftIFG.nii', 'r_leftTP.nii', 'r_leftvOT.nii'};

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed", dataset);
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
roi_dir  = fullfile(proj_dir, 'results', 'anatomical_ROIs', 'resampled_ROIs');

% Add directories to search path
addpath(genpath(util_dir));
addpath(genpath(spm_dir));

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants_motionQC.csv');

%% Set participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.dataset, dataset) & strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);

%% Extract top N most activated voxels
disp("=====Job Start=====")
tic; 
count = 1;

for i = 1:length(subjects.participant_id)
    fprintf('%i. Extracting top %i voxels for %s ...\n', count, top_n, subjects.unique_id{i});
    
    for j = 1:length(rois)
        fprintf('---From %s ...', rois{j});

        % Define ROI
        roi_file = fullfile(roi_dir, rois{j});

        % Define subject's t-statistic map
        deweight_dir = fullfile(data_dir, subjects.participant_id{i}, 'analysis', 'deweight');
        tmap_file = fullfile(deweight_dir, t_map);

        % Create top_voxel directory
        output_dir = fullfile(data_dir, subjects.participant_id{i}, 'top_voxel');
        if ~exist(output_dir, "dir")
            mkdir(output_dir)
        end
    
        % Check if t-statistic map exists
        if ~exist(tmap_file, "file")
            warning('Missing t-statistics map!')
            count = count + 1;
            continue
        end
 
        % Run extract_topVoxels
        output_prefix = sprintf('%s_%s_%s_roi-%s', subjects.unique_id{i}, session, contrast, rois{j}(3:end-4));
        extract_topVoxels(tmap_file, roi_file, output_dir, output_prefix, top_n)
        
        fprintf('Done! \n')

    end
    
    count = count + 1;
    fprintf('\n')
    
end

disp("=====Job Complete=====")
toc;