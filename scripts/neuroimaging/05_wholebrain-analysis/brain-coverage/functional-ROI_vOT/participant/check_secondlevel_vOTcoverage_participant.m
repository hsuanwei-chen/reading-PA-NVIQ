%% check vOT's second level coverage for each participant
%
% This script aims to check how much of the vOT is covered at the second
% level for each participant
% 
% 1) Participant level coverage of vOT 
% 2) Summary file with % coverage of each slice across participants

%% Set input parameters
clear;clc

% Define directories
root_dir    = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir    = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir    = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir    = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir     = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
results_dir = fullfile(proj_dir, "results");

% Create output folder
output_dir = fullfile(results_dir, "check_secondLevelCoverage", "participant");
if ~isfolder(output_dir)
    mkdir(output_dir)
end

% Add directories to search path
addpath(genpath(util_dir));
addpath(spm_dir);

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'preregistration_participants.csv');

% Define paths to ROIs and mask
vOT_file = fullfile(results_dir, "functional_ROIs", "top1000", "leftvOT_top1000_union-mask.nii");

% Define mask image name
mask_fname = 'mask.nii';

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Calculate coverage
disp("=====Job Start=====")
tic;
count = 1;
for i = 1:length(subjects.unique_id)
    fprintf('%i. Loading mask file for %s ... ', count, subjects.unique_id{i}); 
    
    % Read in participant first level mask files
    mask_file = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/', mask_fname);
    mask_info = spm_vol(char(mask_file));
    mask_img  = spm_read_vols(mask_info);
    mask_idx  = find(mask_img == 1);
    
    % Convert linear indices back to voxel coordinates
    [x, y, z] = ind2sub(size(mask_img), mask_idx);
    voxel_coord = [x, y, z, ones(length(x), 1)];
    
    % Convert voxel coordinates back to MNI coordinates
    % For more information: https://nipy.org/nibabel/coordinate_systems.html
    affine = mask_info.mat;
    mni_coord = affine * voxel_coord';

    % Get MNI coordinates for each file
    mask_mni = extract_MNIcoordinates(mask_file);
    vOT_mni  = extract_MNIcoordinates(vOT_file);

    % Add logical vector showing which voxels overlap or are missing
    vOT_mni(:, 4) = ismember(vOT_mni, mask_mni, "rows");

    % Save results as csv
    output_file = fullfile(output_dir, sprintf('%s_vOT_coverage.csv', subjects.unique_id{i}));
    output_tbl = array2table(vOT_mni);
    output_tbl.Properties.VariableNames = [{'MNI_X', 'MNI_Y', 'MNI_Z', 'overlap'}];
    %writetable(output_tbl, output_file);

    % Create group summary table
    if i == 1
        group_output = groupsummary(output_tbl, "MNI_Z", "sum", "overlap");
        group_output.Properties.VariableNames{"sum_overlap"} = subjects.unique_id{i};
    else
        subj_output = groupsummary(output_tbl, "MNI_Z", "sum", "overlap");
        subj_output.Properties.VariableNames{"sum_overlap"} = subjects.unique_id{i};
        group_output.(subjects.unique_id{i}) = subj_output.(subjects.unique_id{i});
    end 
    
    % Save group summary table as csv
    group_output_file = fullfile(results_dir, 'check_secondLevelCoverage', 'vOT_coverage_groupSummary.csv');
    writetable(group_output, group_output_file);    

    fprintf('Done\n');
    count = count + 1;
end
toc;

