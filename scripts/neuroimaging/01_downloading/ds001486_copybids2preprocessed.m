%% Copies data from bids to pre-processing folder
% Original code written by Jin Wang 1/5/2021 for copying data from bids that have multiple sessions.
% A txt file will list subs with >1 T1 image (copy_repeated_anat.m/delete_bad_t1.m to evaluate)
% This script organizes for preprocessing

%% Last modified: 2025/11/09
% 2025/11/09 IC: update to work with new file organization and save storage
% 2025/03/31 IC: update filepaths for R9 environment and catch missing runs
% 2024/11/20 IC: improve readability
% 2024/11/18 IC: updated filepaths and reorganzied script to improve readability

%% Specify filepaths
clear; clc;

% Define root directory
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';

% Define project directory
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');

% Define directory with utility functions
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');  
addpath(genpath(util_dir));

% Define raw data directory
raw_dir = fullfile(root_dir, 'datasets', '6_ds001486', 'bids');

% Define preprocessing directory, where you want to copy your data to
proc_dir = fullfile(proj_dir, 'data', 'neuroimaging', 'preprocessed', 'ds001486');

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants.csv');

%% Specify participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.dataset, 'ds001486') & strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);

% Extract participant IDs
subjects = subjects.participant_id;

%% Specify data search patterns
% Create structure CCN
global CCN;

% Functional image search pattern
CCN.funcf1 = 'sub*_*_task-Rhyming*_bold.ni*';

% Anatomical image search pattern
CCN.anat = '*_T1w.nii.gz'; 

% This is the session. You can define 'ses*' to grab all sessions too.
session = 'ses-T1'; 

%% Track Multiple and Missing Scans
% List of subjects with multiple T1s
% Used in code delete_bad_t1.m later when you want unique t1 to preprocess the data. 
multiple_T1w = 'multiple_T1w.txt';
if exist(multiple_T1w, 'file')
    delete(multiple_T1w);
end
fid2 = fopen([proc_dir '/' multiple_T1w], 'w');

% List of subjects missing functional run-1
no_run1 = 'no_task-run01.txt';
if exist(no_run1, 'file')
    delete(no_run1);
end
fid3 = fopen([proc_dir '/' no_run1], 'w');

% List of subjects missing functional run-2
%no_run2 = 'no_task-run2.txt';
%if exist(no_run2, 'file')
%    delete(no_run2);
%end
%fid4 = fopen([proc_dir '/' no_run2], 'w');

% List of subjects with no functional scans
no_scans = 'no_task-scans.txt';
if exist(no_scans, 'file')
    delete(no_scans);
end
fid5 = fopen([proc_dir '/' no_scans], 'w');

%% Copy BIDS data to pre-processing folder
cd(proc_dir);

% Loop through each subject
disp("=====Job Start=====")
tic; 
count = 1;
for i = 1:length(subjects)
    % Define subject folders
    old_dir = [raw_dir '/' subjects{i} '/' session];
    new_dir = [proc_dir '/' subjects{i} '/' session];
    
    fprintf('%i. Searching for %s data ... \n', count, subjects{i});
    fprintf('Source: ~%s \n', old_dir(29:end));
    fprintf('Destination: ~%s\n', new_dir(29:end))
 
    % Copy data if at least one run of data exists
    if ~isempty(expand_path([old_dir '/func/' '[funcf1]'])) 
        
        % If one run is missing, print which run is missing
        if isempty(expand_path([old_dir '/func/' '[funcf1]']))
            disp('!!! Run-01 is misisng !!!')
            fprintf(fid3, '%s\n',  subjects{i});
        %elseif isempty(expand_path([old_dir '/func/' '[funcf2]']))
        %    disp('!!! Run-02 is missing !!!')
        %    fprintf(fid4, '%s\n',  subjects{i});
        end
        
        % Create directories
        if ~exist(new_dir, 'dir')
            mkdir(new_dir);
            mkdir([new_dir '/func']);
            mkdir([new_dir '/anat']);
        end
        
       % Copy functional data and maintain group permissions
        fprintf('Copying functionals ... '); 
        source{1} = expand_path([old_dir '/func/[funcf1]']);
        %source{2} = expand_path([old_dir '/func/[funcf2]']);
        for j = 1:length(source)
            for jj = 1:length(source{j})
                [f_path, f_name, ext] = fileparts(source{j}{jj});
                mkdir([new_dir '/func/' f_name(1:end-4)]);
                dest = [new_dir '/func/' f_name(1:end-4) '/' f_name ext];
                system(['chmod -R 770 ', fileparts(dest)]);
                copyfile(source{j}{jj}, dest);
                system(['chmod 770 ', dest]);
                gunzip(dest);
                delete(dest);
            end
        end
        fprintf('Done \n');
        
        % Copy anatomicals and maintain group permissions
        fprintf('Copying anatomicals ... '); 
        
        % Check for number of anatomical scans
        sanat = expand_path([old_dir '/anat/[anat]']);
        if length(sanat) > 1
            disp('!!! Multiple T1ws found !!!')
            fprintf(fid2, '%s\n',  subjects{i});
        end
        
        for k = 1:length(sanat)
            [a_path, a_name, ext]=fileparts(sanat{k});
            dt = [new_dir '/anat/' a_name ext];
            system(['chmod -R 770 ', fileparts(dt)]);
            copyfile(sanat{k},dt);
            system(['chmod 770 ', dt]);
            gunzip(dt);
            delete(dt);
        end
        fprintf('Done \n');
        disp(' ');
    else 
        % Print out subjects who are missing scans
        fprintf('!!! NO SCANS FOUND !!!!\n');
        fprintf(fid5, '%s\n',  subjects{i});
        disp(' ')
    end
    count = count + 1;
end

fclose(fid2); fclose(fid3); %fclose(fid4); fclose(fid5);
toc;
disp("=====Job Complete=====")