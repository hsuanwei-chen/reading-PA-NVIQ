%% count_repaired
% This script calculate the movement, accuracy, and rt for each run. written by Jin Wang 1/3/2021, updated 1/5/2021
% The number of volumes being replaced (the second column) and how many chunks of more than 6 consecutive volumes being
% replaced (the third column) are based on the output of art-repair (in the code main_just_for_movement.m). 
% The acc and rt for each condition of a run are calculated based on the
% documented in ELP/bids/derivatives/func_mv_acc_rt/ELP_Acc_RT_final_2020_12_18.doc

%% Last modified: 2025/11/10
% 2025/11/10 IC: update to work with new file organization
% 2025/03/31 IC: update filepaths for R9 environment and catch missing runs
% 2025/01/14 IC: Updated filepaths and reorganzied script to improve readability

%% Specify filepaths
clear; clc

% Defin current working directory
cwd = pwd;

% Define root directory
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';

% Define project directory
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');

% Define directory with utility functions
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');  
addpath(genpath(util_dir));

% Define bids folder and preprocssing folder
dataset = 'ds001894';
preproc_dir = fullfile(proj_dir, 'data', 'neuroimaging', 'preprocessed', dataset);

% Define merged_participants.csv
subj_csv = fullfile(proj_dir, 'data', 'phenotype', 'merged', 'merged_participants.csv');

% Define output folder
output_dir = fullfile(proj_dir, "results", "fMRI_count_repaired");

% Define output filename
output_csv = strcat(output_dir, '/', dataset, '_count_repaired.csv');

%% Define data folder and file parameters for preprocessing
% Create structure CCN
global CCN;

% Define time point
% Define functional data name pattern
CCN.session = 'ses-T1';
CCN.func_pattern = 'sub*_*_task-VVWord*_run*_bold';

%% Specify participants
% Read in mereged_participants.csv
subj_tbl = readtable(subj_csv);

% Filter by dataset and non-excluded
idx = strcmp(subj_tbl.dataset, dataset) & strcmp(subj_tbl.exclude, 'NA');
subjects = subj_tbl(idx, :);

%% Count number of repaired chunks
cd(preproc_dir);
n = 6; %number of consecutive volumes being replaced. no more than 6 consecutive volumes being repaired.

% Initialize variables to save summary values
motion_header = {
    'unique_id', 'dataset', 'subject_id', 'run_name', 'repaired_num', ... 
    'repaired_perc', 'chunks_num', 'FD_mean', 'FD_num_03', 'FD_perc_03' ...
    'num_volume'
};
group_motion_tbl = array2table(zeros(0, length(motion_header)));
group_motion_tbl.Properties.VariableNames = motion_header;

for i = 1:length(subjects.participant_id)
    
    % Define subject folder and their fMRI task folder
    func_p = [preproc_dir '/' subjects.participant_id{i}];
    func_f = expand_path([func_p '/[session]/func/[func_pattern]/']);
    
    for j = 1:length(func_f)
                
        % Find all the runs
        run_n = func_f{j}(1:end-1);
        [run_p, run_name] = fileparts(run_n);
        cd(run_n);
        
        %Print what subject session is currently being analyzed
        fprintf('%i. Counting repaired for %s %s ... ', i, dataset, run_name)
        
        % Read in movement data from art_repair
        fileid = fopen('art_repaired.txt');
        m = fscanf(fileid, '%f');
        
        % Size returns number of rows (num_repaired), number of columns (col)
        [repaired_num, col] = size(m);
        
        % Transpose m; test if the difference between each number is equal to 1 
        x = diff(m') == 1;
        
        % Returns each position when difference is equal to 1 after the
        % difference was not equal to 1 (start)
        ii = strfind([0 x 0], [0 1]);
        % Returns each position when difference is equal to 1 before the
        % difference is not equal to 1 (end)
        jj = strfind([0 x 0], [1 0]);
        % Check if a sequence has more than 6 consecutive volumes repaired
        out = ((jj-ii) >= n);
        
        % Determine number of chuncks
        if out == 0
            num_chunks = 0;
        else
            num_chunks = sum(out(:) == 1);
        end
       
        % Locate the motion parameter file
        rp_file = dir('rp*');
        
        % Calculate framewise displacement
        FD = fmri_FD(fullfile(rp_file.folder, rp_file.name));
        vol_num = length(FD);
        
        FD_mean = mean(FD);
        FD_num_03 = sum(FD >= 0.3); % see Smith et al. 2022
        FD_perc_03 = FD_num_03/vol_num;
        
        % Calcualte percent of repaired volumes
        repaired_perc = repaired_num/vol_num;
        
        % Aggregate motion summary for individual
        motion_sum = {
            subjects.unique_id{i}, subjects.dataset{i}, ...
            subjects.participant_id{i}, run_name, repaired_num, ...
            repaired_perc, num_chunks, FD_mean, FD_num_03, ...
            FD_perc_03, vol_num
        };
        motion_tbl = cell2table(motion_sum);
        motion_tbl.Properties.VariableNames = motion_header;
        group_motion_tbl = [group_motion_tbl; motion_sum];
        
        fprintf('Done! \n');   
        
        clear func_p run_n run_p run_name m repaired_num x ii jj ...
              out repair_perc num_chuncks FD FD_mean FD_num_03 ... 
              FD_perc_03 vol_num
        
    end
end

% Write output into excel
writetable(group_motion_tbl, output_csv)

cd(cwd)
