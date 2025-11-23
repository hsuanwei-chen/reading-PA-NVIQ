%% Check coregistraion
% This script aims to create a visualization to check registration between
% the structural and anatomical scans

%% Set input parameters
clear; clc;

% Define current working directory
cwd = pwd;

% Define root directory
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';

% Define project directory
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');

% Define preprocessed directory
proc_dir = fullfile(proj_dir, 'data', 'neuroimaging', 'preprocessed/');

% Define directory with utility functions
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');  
addpath(genpath(util_dir));

% Define SPM directory
spm_path = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
addpath(genpath(spm_path));

% Define path to template brain
tpm= fullfile(spm_path, 'tpm', 'TPM.nii');

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants_motionQC.csv');

%% Specify participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);
            
%% Run coreg_check
% Initialize
spm('defaults','fmri');
spm_jobman('initcfg');
spm_figure('Create','Graphics','Graphics');

% Dependency and sanity checks
if verLessThan('matlab','R2013a')
    error('Matlab version is %s but R2013a or higher is required',version)
end

% SPM version
req_spm_ver = 'SPM12 (6225)';
spm_ver = spm('version');
if ~strcmp( spm_ver,req_spm_ver )
    error('SPM version is %s but %s is required',spm_ver,req_spm_ver)
end

disp("=====Job Start=====")
for idx = 1:length(subjects.unique_id)
    fprintf('%i. Processing %s ...\n', idx, subjects.unique_id{idx});
    
    % Define subject folder
    subj_folder = fullfile(proc_dir, subjects.dataset{idx}, subjects.participant_id{idx});

    % Reorganize figures folder
    fig_folder = fullfile(subj_folder, 'figures');
    qc_folder = dir(fullfile(subj_folder, '**', 'motion_QC'));

    if ~isempty(qc_folder)
        disp('---Reorganizing figures folder ...')
        qc_folder = qc_folder(1).folder;
        movefile(fullfile(qc_folder, '*'), fig_folder);
        rmdir(qc_folder);
    else
        disp('Figures folder is already organized!')
    end

    % Run coreg_check
    disp('---Running coreg_check ...')
    wmeanfunc = dir(fullfile(subj_folder, '**', 'wmean*.nii'));
    wmeanfunc = fullfile(wmeanfunc.folder, wmeanfunc.name);
    coreg_check(wmeanfunc, fig_folder, tpm);
    fprintf('Done! \n')
end
disp("=====Job Complete=====")