%% createROI_left_TP
% Last edited: 2025-11-23
% 2025-11-23 - updated to allow functions to work
% 2025-05-07 - script was created

%% Set input parameters
% Define root directory
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';

% Define project directory
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');

% Define ROI directory
roi_dir = fullfile(proj_dir, "results", "anatomical_ROIs");

% Define SPM12 directory
spm_path = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
addpath(genpath(spm_path));

% Define ROI paths
roi_path = fullfile(roi_dir, 'AAL_atlas', 'left_STG_SMG_roi.mat');
box_roi_path = fullfile(roi_dir, 'box_ROIs', 'box_left_STG_SMG_roi.mat');
trimmed_roi_mat = fullfile(roi_dir, 'trimmed_ROIs', 'left_TP_roi.mat');
trimmed_roi_nii = fullfile(roi_dir, 'trimmed_ROIs', 'left_TP.nii');

% Marsbar switch on
marsbar('on')

%% Trim Left STG + Left SMG
% Goal: left pSTG (y-axis < -25) + left SMT

% 1) ROIs were made using WFU PickAtlas Tool 
% 2) ROIs were then changed from .nii files to .mat files using Marsbar 
% Steps to get create .mat files: 
% -- marsbar > ROI definition > Import > Number Labelled ROI Image

% Read original ROI
roi = maroi('load', roi_path);

% Check original ROI
% Range in X: [-68 -36]
% Range in Y: [-56 6]
% Range in Z: [-16 44]
mars_display_roi('display', roi);

% Make a box ROI to do trimming
% Keep the range in X and Z the same
% Bc we want ROIs < -25 (more posterior), we set the box ROI's minimum to -25. 
box_limits_1 = [-68 -36; -25 6; -16 44]'; 
box_centre_1 = mean(box_limits_1);
box_widths = abs(diff(box_limits_1));
box_roi_1 = maroi_box(struct('centre', box_centre_1, 'widths', box_widths));
saveroi(box_roi_1, box_roi_path);

% Check box ROI
% range in y is -24 to 6 because voxel sizes are 2mm.
mars_display_roi('display', box_roi_1);

% Combine BOX and anatomical ROI
trimmed_roi = roi & ~ box_roi_1;
trimmed_roi = label(trimmed_roi, 'left_TP');

% Steps for GUI (manual): 
% -- marsbar > ROI definition > transform > combine ROIs > 
% -- select left_STG_SMG_roi.mat first, then select box_left_left_STG_SMG_roi.mat
% -- function: r1 & ~ r2 (keep voxels only in r1 but not in r2)

% Save trimmed ROI to MarsBaR ROI file in current directory
saveroi(trimmed_roi, trimmed_roi_mat);

% Check original and trimmed ROI
roi_array = {roi, trimmed_roi};
mars_display_roi('display', roi_array);

% Save trimmed ROIs .nii file
mars_rois2img(trimmed_roi, char(trimmed_roi_nii));
