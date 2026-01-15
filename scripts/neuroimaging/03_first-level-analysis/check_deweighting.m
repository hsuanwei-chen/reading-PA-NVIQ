%% check_dweighting
% This script aims to check whether deweighting of motion outlier volumnes
% was implmeneted in the first-level model
%
% Note that for participants with multiple runs, please only keep the runs
% that were used in the first-level model in the subject's preprocessed
% folder

%% Set filepaths
clear;clc

% Define file with reparied volumes
deweight_txt = 'art_repaired.txt';

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed");
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 

% Add directories to search path
addpath(genpath(util_dir));
addpath(genpath(spm_dir));

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants_motionQC-coverage.csv');

% Define output csv
output_dir = fullfile(proj_dir, "results", "check_deweighting");
if ~exist(output_dir, "dir")
    mkdir(output_dir)
end
deweight_csv = fullfile(output_dir, "merged_deweighting.csv");

%% Set participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);

% Initialize variables to save summary values
deweight_header = {'unique_id', 'dataset', 'subject_id', 'num_repaired', 'total_deweighted'};
deweight_tbl = cell(length(subjects.unique_id), length(deweight_header));

%% Check deweigthing vector
disp("=====Job Start=====")
tic;
count = 1;
for i = 1:length(subjects.participant_id)
    fprintf('%i. Checking deweighting vector for %s ...\n', count, subjects.unique_id{i});
    
    % Find deweight SPM matrix
    deweight_dir = fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, 'analysis', 'deweight');
    spm_file = fullfile(deweight_dir, "SPM.mat");
    
    % Find art_repaired.txt
    art_list = dir(fullfile(data_dir, subjects.dataset{i}, subjects.participant_id{i}, '**/sub-*', deweight_txt));
    
    % Organize art_repaired.txt depending on number of runs
    if isequal(numel(art_list), 1)
        fprintf('---One run found ... \n')

        % Read in art_repaired.txt
        art_txt = fullfile(art_list.folder, art_list.name);
        repaired_list = load(art_txt);
        
        % Load SPM matrix 
        load(spm_file)
        weights = SPM.xX.W;
    
        % Count number of repaired scans
        num_repaired = length(repaired_list);
    
        % Check if deweighting is appropriately applied 
        total_deweighted = sum(weights(repaired_list, :), 'all');
        total_deweighted = full(total_deweighted);

        % Report deweighting results
        fprintf('---Number of repaired volume: %i ... \n', num_repaired);
        fprintf('---Sum of its deweighting vector: %.2f ... \n', total_deweighted)
        
        % Save results
        sub_deweight = {
            subjects.unique_id{i}, subjects.dataset{i}, ...
            subjects.participant_id{i}, num_repaired, total_deweighted
        };
        deweight_tbl(i, :) = sub_deweight;

        % Clear variable
        clear repaired_list

    elseif isequal(numel(art_list), 2)
        fprintf('---Two runs found ... \n')
        
        % Read in number of volumes from run-01
        for j = 1:numel(art_list)
            art_txt = fullfile(art_list(j).folder, art_list(j).name);
            repaired_vols = load(art_txt);
            repaired_list{j} = repaired_vols;
            
            if contains(art_txt, {'run-1', 'run-01'})
                rp_file = dir(fullfile(art_list(j).folder, "rp_*"));
                rp_fname = fullfile(rp_file.folder, rp_file.name);
                rp_data = load(rp_fname);
                nvols = numel(rp_data(:, 1));
            end

        end
        
        % Add number of volumes to run-02
        repaired_list{j} = repaired_list{j} + nvols;
        repaired_list = [repaired_list{:}];

        % Load SPM matrix 
        load(spm_file)
        weights = SPM.xX.W;
    
        % Count number of repaired scans
        num_repaired = length(repaired_list);
    
        % Check if deweighting is appropriately applied 
        total_deweighted = sum(weights(repaired_list, :), 'all');
        total_deweighted = full(total_deweighted);

        % Report deweighting results
        fprintf('---Number of repaired volume: %i ... \n', num_repaired);
        fprintf('---Sum of its deweighting vector: %.2f ... \n', total_deweighted)
        
        % Save results
        sub_deweight = {
            subjects.unique_id{i}, subjects.dataset{i}, ...
            subjects.participant_id{i}, num_repaired, total_deweighted
        };
        deweight_tbl(i, :) = sub_deweight;

        % Clear variable
        clear repaired_list
    end

    count = count + 1;
    fprintf('\n')
    
end

% Write results to CSV
deweight_tbl = cell2table(deweight_tbl);
deweight_tbl.Properties.VariableNames = deweight_header;
writetable(deweight_tbl, deweight_csv)

disp("=====Job Complete=====")
toc
