%% extract_betas_leftIFG_unionMask
%
% This script aims to extract beta values from each participant's
% contrast map for voxels within the union map

%% Set input parameters
clear;clc

% Define contrast map and union ROIs
top_n = 1000;
contrast = "con-NCFix";
con_map = 'con_0001.nii';
rois = {
    'leftIFG_top1000_union-mask.nii'; 
    'leftTP_top1000_union-mask.nii'; 
    'leftvOT_top1000_union-mask.nii'
};

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
roi_dir  = fullfile(proj_dir, "results", "functional_ROIs", sprintf('top%i', top_n));
out_dir  = fullfile(proj_dir, "results", "harmonization", sprintf('top%i', top_n));

% Add directories to search path
addpath(genpath(util_dir));
addpath(genpath(spm_dir));

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants_motionQC.csv');

%% Set participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);

%% Extract betas within union mask
disp("=====Job Start=====")
tic;
count = 1;

for i = 1:length(rois)     
    fprintf('Extracting betas within %s ...\n', rois{i});
    
    % Define ROI
    roi_file = char(fullfile(roi_dir, rois{i}));

    % Check if contrast map exists
    if ~exist(roi_file, "file")
        warning('Missing union mask!')
        continue
    end
    
    % Read in union mask
    roi_info = spm_vol(roi_file);
    roi_img  = spm_read_vols(roi_info, 1);
    roi_idx = find(roi_img == 1);

    % Convert linear indices back to voxel coordinates
    [x, y, z] = ind2sub(size(roi_img), roi_idx);
    voxel_coord = [x, y, z, ones(length(x), 1)];
    
    % Convert voxel coordinates back to MNI coordinates
    % For more information: https://nipy.org/nibabel/coordinate_systems.html
    affine = roi_info.mat;
    mni_coord = affine * voxel_coord';

    % Initialize data storage
    subj_data = [mni_coord(1:3, :)', zeros(length(roi_idx), length(subjects.unique_id))];

    for j = 1:length(subjects.unique_id)
        fprintf('---%i. From %s ... ', count, subjects.unique_id{j});

        % Define subject's contrast map
        subj_dir = fullfile(data_dir, subjects.dataset{j}, subjects.participant_id{j});
        deweight_dir = fullfile(subj_dir, 'analysis', 'deweight');
        con_file = char(fullfile(deweight_dir, con_map));

        % Check if contrast map exists
        if ~exist(con_file, "file")
            warning('Missing contrast map!')
            count = count + 1;
            continue
        end        

        % Read in contrast file
        con_info = spm_vol(con_file);
        con_img  = spm_read_vols(con_info);  
        
        % Extract betas within union ROI
        con_vals = con_img(roi_idx);
        subj_data(:, j+3) = con_vals;
        
        count = count + 1;
        fprintf('Done! \n');
    end
    
    % Save results as csv
    output_file = fullfile(out_dir, sprintf('betas_%s_%s.csv', contrast, rois{i}(1:end-4)));
    output_tbl = array2table(subj_data);
    output_tbl.Properties.VariableNames = [{'MNI_X', 'MNI_Y', 'MNI_Z'}, subjects.unique_id'];
    writetable(output_tbl, output_file);

    % Reset count
    count = 1;
    fprintf('\n')    
end

disp("=====Job Complete=====")
toc;