%% createUnionMap
%
% This script aims to create a union map across all participants

%% Set input parameters
clear;clc

% Define prefix of top N mask
top_n = 1000;
rois = {'r_leftIFG.nii', 'r_leftTP.nii', 'r_leftvOT.nii'};

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
roi_dir  = fullfile(proj_dir, "results", "functional_ROIs", sprintf('top%i', top_n));

% Add directories to search path
addpath(genpath(util_dir));
addpath(genpath(spm_dir));

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants_motionQC-coverage.csv');

%% Set participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);

%% Extract top N most activated voxels
disp("=====Job Start=====")
tic; 
count = 1;

for i = 1:length(rois)     
    fprintf('Creating union mask for %s ...\n',rois{i});
    
    for j = 1:length(subjects.unique_id)

        if j == 1
            % Use the first subject to initialize union mask
            fprintf('---%i. Origin %s ... ', count, subjects.unique_id{j});
    
            % Define subjects top N mask
            topVoxel_dir = fullfile(data_dir, subjects.dataset{j}, subjects.participant_id{j}, 'top_voxel');
            topVoxel_mask = dir(fullfile(topVoxel_dir, sprintf('*%s*.nii', rois{i}(3:end-4))));
            
            % Make sure there are no dupicate masks
            if ~isequal(size(topVoxel_mask), [1, 1])
                warning("There may be multiple masks for the ROI!")
            end
            
            % Read in mask file
            topVoxel_mask_file = fullfile(topVoxel_mask.folder, topVoxel_mask.name);
            mask_info = spm_vol(topVoxel_mask_file);
            
            % Create union map
            union_mask = spm_read_vols(mask_info) > 0; %logical map
            fprintf('Current voxel count: %i ... ', nnz(union_mask));

        else
            % Add second subejct and more to union map
            fprintf('---%i. Adding %s ... ', count, subjects.unique_id{j});
            
            % Define subjects top N mask
            topVoxel_dir = fullfile(data_dir, subjects.dataset{j}, subjects.participant_id{j}, 'top_voxel');
            topVoxel_mask = dir(fullfile(topVoxel_dir, sprintf('*%s*.nii', rois{i}(3:end-4))));
            
            % Make sure there are no dupicate masks
            if ~isequal(size(topVoxel_mask), [1, 1])
                warning("There may be multiple masks for the ROI!")
            end
            
            % Read in mask file
            topVoxel_mask_file = fullfile(topVoxel_mask.folder, topVoxel_mask.name);
            mask_info = spm_vol(topVoxel_mask_file);
            
            % Update union map with next subject
            temp_map = spm_read_vols(mask_info) > 0; %logical map
            union_mask = union_mask | temp_map;
            union_voxel_num = nnz(union_mask);

            fprintf('Current voxel count: %i ... ', union_voxel_num);
        end

        count = count + 1;
        fprintf('Done! \n');
        
    end
    
    % Reset count
    count = 1;
    fprintf('\n')
    
    % Save union mask
    % Set mask header information
    mask_hdr = mask_info;
    mask_hdr.fname = char(fullfile(roi_dir, sprintf('%s_top%i_union-mask.nii', rois{i}(3:end-4), top_n)));
    mask_hdr.descrip = sprintf('Union mask created from top %i voxels based on t-statistic', top_n);
    
    % Write mask into 3D image
    spm_write_vol(mask_hdr, union_mask);

end

disp("=====Job Complete=====")
toc;