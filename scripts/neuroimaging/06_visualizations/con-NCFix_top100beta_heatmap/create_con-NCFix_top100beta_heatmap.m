%% create top 100 beta heatmap
%
% This script aims to extract top 100 beta values from each participant's
% contrast map for voxels within the union map

%% Set input parameters
clear;clc

% Define contrast and ROI filenames
top_n = 100;
contrast = "con-NCFix";
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

% Create ouput directory
output_dir = fullfile(proj_dir, "results", "visualizations", "top100_beta_heatmap");
if ~exist(output_dir, "dir")
    mkdir(output_dir)
end

% Add directories to search path
addpath(genpath(util_dir));
addpath(spm_dir);

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'preregistration-amendment_participants.csv');

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Create top 100 beta heatmap
disp("=====Job Start=====")
tic; 
count = 1;

for i = 1:length(rois)
    fprintf('Creating top 100 beta heatmap for %s ... \n', rois{i}); 

    for j = 1:length(subjects.unique_id)
        if j == 1
            fprintf('---%i. Adding mask file for %s ... ', count, subjects.unique_id{j}); 
            
            % Define subject top_voxel folder
            subj_dir = fullfile(data_dir, subjects.dataset{j}, subjects.participant_id{j}, "top_voxel");
            
            % Define subject mask file
            mask_prefix = sprintf('%s_%s_%s', subjects.unique_id{j}, contrast, rois{i}(1:end-4));            
            mask_file = fullfile(subj_dir, sprintf("%s_top%iBeta_mask.nii", mask_prefix, top_n));

            % Read in subject mask file
            mask_info = spm_vol(char(mask_file));
            mask_img  = spm_read_vols(mask_info);
    
            % Create heatmap
            heatmap_img = zeros(size(mask_img));
            heatmap_img = heatmap_img + mask_img;
    
            fprintf('Done\n');
            count = count + 1;
        else
            fprintf('---%i. Adding mask file for %s ... ', count, subjects.unique_id{j}); 
            
            % Define subject top_voxel folder
            subj_dir = fullfile(data_dir, subjects.dataset{j}, subjects.participant_id{j}, "top_voxel");
            
            % Define subject mask file
            mask_prefix = sprintf('%s_%s_%s', subjects.unique_id{j}, contrast, rois{i}(1:end-4));            
            mask_file = fullfile(subj_dir, sprintf("%s_top%iBeta_mask.nii", mask_prefix, top_n));

            % Read in subject mask file
            mask_info = spm_vol(char(mask_file));
            mask_img  = spm_read_vols(mask_info);
    
            % Create heatmap
            heatmap_img = heatmap_img + mask_img;
            
            fprintf('Done\n');
            count = count + 1;
        end
    end

    % Save top 100 beta heatmap
    % Set mask header information
    heatmap_hdr = mask_info;
    heatmap_hdr.fname = char(fullfile(output_dir, sprintf("%s_top%iBeta_heatmap.nii", rois{i}(1:end-4), top_n)));
    heatmap_hdr.dt = [16, 0];
    heatmap_hdr.descrip = sprintf('Heatmap of the top 100 beta across participants');
    
    % Write mask into 3D image
    spm_write_vol(heatmap_hdr, heatmap_img);
    
    % Save top 100 beta percent heatmap
    perc_heatmap_img = heatmap_img / numel(subjects.participant_id);
    heatmap_hdr.fname = char(fullfile(output_dir, sprintf("%s_top%iBeta_perc-heatmap.nii", rois{i}(1:end-4), top_n)));
    heatmap_hdr.descrip = sprintf('Percent Heatmap of the top 100 beta across participants');
    
    % Write mask into 3D image
    spm_write_vol(heatmap_hdr, perc_heatmap_img);

    % Reset count
    count = 1;
    fprintf('\n');

end

disp("=====Job Complete=====")
toc;
