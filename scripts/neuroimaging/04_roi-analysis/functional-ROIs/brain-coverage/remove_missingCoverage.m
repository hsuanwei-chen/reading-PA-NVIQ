%% remove_missingCoverage
%
% This script aims to remove downloaded participant folders identified as
% >20% missing coverage of a functional ROI.
 
%% Set input parameters
clear;clc

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants_motionQC-coverage.csv');

%% Set participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = contains(subj_tbl.exclude, 'coverage');
subjects = subj_tbl(idx, :);

%% Remove participants with missing coverage
disp("=====Job Start=====")
fprintf('Found %i participants folders to remove due to missing brain coverage.\n', length(subjects.unique_id));
count = 1;

for i = 1:length(subjects.unique_id)
    folder_path = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i});

    if isfolder(folder_path)
        fprintf('%i. Removing %s ... ', count, folder_path);
        try
            rmdir(folder_path, 's');   % delete folder recursively
            disp('Done')
        catch ME
            warning('Could not remove %s: %s', folder_path, ME.message);
        end
    else
        fprintf('Folder not found: %s\n', folder_path);
    end

    count = count + 1;
end

disp("=====Job Complete=====")