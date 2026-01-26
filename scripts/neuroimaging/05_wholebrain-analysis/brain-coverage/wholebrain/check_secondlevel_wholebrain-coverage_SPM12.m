%% Second level analysis
%currently I only write the one sample t test and
%regression analysis, which are the two mostly used.
%Jin Wang 3/19/2019

%% Specify filepaths
clear;clc

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
out_dir  = fullfile(proj_dir, "results", "second-level-analysis", "one-sample-t");

% Add directories to search path
addpath(genpath(util_dir));
addpath(spm_dir);

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'preregistration_participants.csv');

% Choose your analysis method
test=1; %1 one-sample t test, 2 mutiple regression analysis
cov=0;
cov_num=0;

%% Set participants
% Read in mereged_participants.csv
subjects = readtable(subj_csv);

%% Second level analyses
% Initialize
spm('defaults','fmri');
spm_jobman('initcfg');
spm_figure('Create','Graphics','Graphics');

% Dependency and sanity checks
if verLessThan('matlab','R2013a')
    error('Matlab version is %s but R2013a or higher is required',version)
end

req_spm_ver = 'SPM12 (6225)';
spm_ver = spm('version');
if ~strcmp( spm_ver,req_spm_ver )
    error('SPM version is %s but %s is required',spm_ver,req_spm_ver)
end

% Load the contrast file path for each subject
disp("=====Job Start=====")
scan=[];
contrast=[];

count = 1;
for i = 1:length(subjects.unique_id)
    fprintf('%i. Loading contrast file for %s  ... ', count, subjects.unique_id{i}); 
    deweight_spm = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '/analysis/deweight/SPM.mat');
    deweight_p = fileparts(deweight_spm);
    
    load(deweight_spm);
    contrast_names=[];
    scan_files=[];

    for ii = 1:length(SPM.xCon)
        contrast_names{ii,1} = SPM.xCon(ii).name;
        scan_files{ii,1} = char(fullfile(deweight_p, SPM.xCon(ii).Vcon.fname));
    end
    
    contrast{i} = contrast_names;
    scan{i} = scan_files;
    count = count + 1;

    fprintf('Done\n');
end

allscans=[];
for i=1:length(scan{1})
    for j=1:length(subjects.unique_id)
        allscans{i}{j,1}=[scan{j}{i} ',1'];
    end
end

%make output folder for each contrast
if ~exist(out_dir, "dir")
    mkdir(out_dir);
end

cd(out_dir);
for ii = 1:length(contrast{1})
    out_dirs{ii} = char(fullfile(out_dir, contrast{1}{ii}));
    if ~exist(out_dirs{ii}, "dir")
        mkdir(out_dirs{ii});
    end
end

%covariates
%pass the covariates to a struct
if cov==1
    covariates.name = name;

    for i = 1:cov_num
        values{i} = transpose(val{i});
    end
    
    covariates.values=values;
else
    covariates={};
end

if test == 1 % one-sample t test
    onesample_t(out_dirs, allscans, covariates);
    
elseif test == 2 %multiple regression analysis
    multiple_regression(out_dirs,allscans,covariates);
    
end
