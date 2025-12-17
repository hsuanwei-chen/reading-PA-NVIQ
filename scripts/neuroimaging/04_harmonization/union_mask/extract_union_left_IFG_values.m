% Clean workspace and variables
clear; clc;

tic; 
% Define root directory
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
firstlevel_dir = fullfile(root_dir, 'Isaac', 'reading-PA-NVIQ', 'first_level');
harmonization_dir = fullfile(root_dir, 'Isaac', 'reading-PA-NVIQ', 'typical_data_analysis', '4harmonization');
addpath(genpath(harmonization_dir));

% Define SPM directory
spm_path = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
addpath(genpath(spm_path));

% Define masks
mask = fullfile(harmonization_dir, 'masks', 'union_left_IFG-Oper-Tri_NC-vs-fixation_mask.nii');

% Initialize data storage
sub_data = [];

% List all contrast images
contrast_imgs = dir(fullfile(firstlevel_dir, '*.nii')); 

% Excel output file
output_file = fullfile(harmonization_dir, 'union_left_IFG_values.csv');

%Start to preprocess data from here
disp("=====Job Start=====")
count = 1;
% Loop through each dataset folder
for i = 1:length(contrast_imgs)
    % Full path to the fMRI data file
    contrast = fullfile(firstlevel_dir, contrast_imgs(i).name);
            
    % Read in individual contrast map
    fprintf('%i. Extracting values from: ~%s ... ', count, contrast(73:end));
    sub_contrast = spm_read_vols(spm_vol(contrast));  
    
    % Extract values from union ROI
    roi_img = spm_read_vols(spm_vol(mask), 1);
    indx = find(roi_img > 0);
    sub_roi_values = sub_contrast(indx);
    
    % Define subject-levle output
    sub_data = [sub_data sub_roi_values];
    
    fprintf('Done \n');
    count = count + 1;
end

% Write data to Excel file
if ~isempty(sub_data)
    % Convert to table and write to Excel
    output_table = array2table(sub_data);
    writetable(output_table, output_file);
    fprintf('Data written to: %s\n', output_file);
else
    fprintf('No data found to write to Excel.\n');
end

disp("=====Job Complete=====")
toc;