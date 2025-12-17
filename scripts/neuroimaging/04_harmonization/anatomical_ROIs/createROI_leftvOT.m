%% createROI_left_vOT
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
roi_path = fullfile(roi_dir, 'AAL_atlas', 'left_FG_ITG_roi.mat');
box_roi_1_path = fullfile(roi_dir, 'box_ROIs', 'box_FG_ITG_1_roi.mat');
box_roi_2_path = fullfile(roi_dir, 'box_ROIs', 'box_FG_ITG_2_roi.mat');
box_roi_3_path = fullfile(roi_dir, 'box_ROIs', 'box_FG_ITG_3_roi.mat');
trimmed_roi_mat = fullfile(roi_dir, 'trimmed_ROIs', 'left_vOT_roi.mat');
trimmed_roi_nii = fullfile(roi_dir, 'trimmed_ROIs', 'left_vOT.nii');

% Marsbar switch on
marsbar('on')

%% Trim Left FG + Left ITG
% Goal: left FG + left ITG (y-axis between -30 and -75; z-axis between -26 to 4

% 1) ROIs were made using WFU PickAtlas Tool 
% 2) ROIs were then changed from .nii files to .mat files using Marsbar 
% Steps to get create .mat files: 
% -- marsbar > ROI definition > Import > Number Labelled ROI Image

% Read original ROI
roi = maroi('load', roi_path);

% Check original ROI
% Range in X: [-70 -14]
% Range in Y: [-94 14]
% Range in Z: [-46 -4]
mars_display_roi('display', roi);

% Make a box ROI to do trimming
% Keep the range in X and Z the same; only change the range in Y
box_limits_1 = [-70, -14; -28 14; -46, -4]'; 
box_centre_1 = mean(box_limits_1);
box_widths_1 = abs(diff(box_limits_1));
box_roi_1 = maroi_box(struct('centre', box_centre_1, 'widths', box_widths_1));
saveroi(box_roi_1, box_roi_1_path);

% Check box ROI
mars_display_roi('display', box_roi_1);

% Make a box ROI to do trimming
% Keep the range in X and Z the same; only change the range in Y
box_limits_2 = [-70, -14; -94, -78; -46, -4]'; 
box_centre_2 = mean(box_limits_2);
box_widths_2 = abs(diff(box_limits_2));
box_roi_2 = maroi_box(struct('centre', box_centre_2, 'widths', box_widths_2));
saveroi(box_roi_2, box_roi_2_path);

% Check box ROI
mars_display_roi('display', box_roi_2);

% Make a box ROI to do trimming
% Keep the range in X and Y the same; only change the range in Z
box_limits_3 = [-70, -14; -94, -14; -46, -28]'; 
box_centre_3 = mean(box_limits_3);
box_widths_3 = abs(diff(box_limits_3));
box_roi_3 = maroi_box(struct('centre', box_centre_3, 'widths', box_widths_3));
saveroi(box_roi_3, box_roi_3_path);

% Check box ROI
mars_display_roi('display', box_roi_3);

% Combine BOX and anatomical ROI
% -- function: r1 & ~ (r2 | r3 | r4) (keep voxels only in r1 but not in either r2 or r3 or r4)
trimmed_roi = roi & ~ (box_roi_1 | box_roi_2 | box_roi_3);
trimmed_roi = label(trimmed_roi, 'left_vOT');

% Save trimmed ROI to MarsBaR ROI file in current directory
saveroi(trimmed_roi, trimmed_roi_mat);

% Check original and trimmed ROI
roi_array = {roi, trimmed_roi};
mars_display_roi('display', roi_array);

% Save trimmed ROIs .nii file
mars_rois2img(trimmed_roi, char(trimmed_roi_nii));
