%% First level analysis, written by Jin Wang 3/15/2019
% You should define your conditions, onsets, duration, TR.
% The repaired images will be deweighted from 1 to 0.01 in the first level
% estimation (we changed the art_redo.m, which uses art_deweight.txt as default to deweight the scans to art_redo_jin.txt, which we uses the art_repaired.txt to deweight scans).
% The difference between art_deiweghted.txt and art_repaired.txt is to the
% former one is more wide spread. It not only mark the scans which was repaired to be deweighted, but also scans around it to be deweighted.
% The 6 movement parameters we got from realignment is added into the model regressors to remove the small motion effects on data.

% Make sure you run clear all before running this code. This is to clear all existing data structure which might be left by previous analysis in the work space.

% This code is for ELP project specifically to deal with its repeated runs and run-<> is after acq- that would cause run-01 is after run-02 when specifying the model.

%% Last modified: 2025/11/21
% 2025/11/21 IC: updated with new motion criteria
% 2025/01/24 IC: Updated filepaths and reorganzied script to improve readability

function ds001894_firstlevel_subject(subjects)
%% Specify filepaths;
% Define root directory
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';

% Define project directory
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');

% Define directory with utility functions
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');  
addpath(genpath(util_dir));

% Define SPM directory
spm_path = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 
addpath(genpath(spm_path));

% Define first-level modeling folder
analysis_folder = 'analysis';

% Define deweighted modleing folder
model_deweight = 'deweight';

% Define data path
data = struct();

% 1 means you did copy the events.tsv into your preprocessed folder
% 0 means you cleaned the events.tsv in your preprocessed folder
events_file_exist=0;

% Define BIDS folder
% If you assign 0 to events_file_exist, then you mask fill in this path, 
% so it can read events.tsv file for individual onsets from bids folder
bids_folder = fullfile(root_dir, 'datasets', '2_ds001894', 'bids');

%% Define data folder and file parameters for preprocessing
% Create structure CCN
global CCN

% Define folder with preprocessed data
% Define dataset
% Define time point
% Define functional folder name pattern
% Define preprocessed data suffix
% Define movement file after slice time correction
CCN.preprocessed_folder = 'data/neuroimaging/preprocessed';
CCN.dataset = 'ds001894';
CCN.session = 'ses-T1';
CCN.func_pattern = 'sub*';
CCN.file = 'vs6_wasub*bold.nii';
CCN.rpfile = 'rp_a';
 
%% Specify Task Conditions
% Define your task conditions, each run is a cell
% Rows - 'O+P+' 'O+P-' 'O-P+' 'O-P-' 'control, fixation color change' 'perceptual, symbol comparison'
conditions{1}={'O+P+' 'O+P-' 'O-P+' 'O-P-' 'control' 'perceptual'};
conditions{2}={'O+P+' 'O+P-' 'O-P+' 'O-P-' 'control' 'perceptual'};

% Duration = 0, if design is event-related
dur = 0;

% TR
TR = 2;

% Define your contrasts, make sure your contrasts and your weights should be matched.
contrasts = {'non-conflicting_vs_fixation'};
% Contrast is set up this way to account for two runs, see Andy Brain Blog.
% nc_fix = [0.5/2, 0, 0, 0.5/2, -1/2, 0]
nc_fix = [0.25 0 0 0.25 -0.5 0]; 

%adjust the contrast by adding six 0s into the end of each session
rp_w=zeros(1,6);
weights={[nc_fix rp_w nc_fix rp_w]};

%% First-level analysis
% Check if you define your contrasts in a correct way
if length(weights)~=length(contrasts)
    error('the contrasts and the weights are not matched');
end

% Initialize
spm('defaults','fmri');
spm_jobman('initcfg');
spm_get_defaults('cmdline', true);
%spm_figure('Create','Graphics','Graphics');

% Dependency and sanity checks
% Check MATLAB version
if verLessThan('matlab','R2013a')
    error('Matlab version is %s but R2013a or higher is required',version)
end

% Check SPM12 version
req_spm_ver = 'SPM12 (6225)';
spm_ver = spm('version');
if ~strcmp( spm_ver,req_spm_ver )
    error('SPM version is %s but %s is required',spm_ver,req_spm_ver)
end

%Start to preprocess data from here
disp("=====Job Start=====")
try
    fprintf('Processing first-level analysis on %s_%s ... ', CCN.dataset, subjects); 
    
    % Define subjects folder
    CCN.subject=[proj_dir '/' CCN.preprocessed_folder '/' CCN.dataset '/' subjects];
    
    % Specify the outpath,create one if it does not exist
    out_path=[CCN.subject '/' analysis_folder];
    if ~exist(out_path)
        mkdir(out_path)
    end
     
    % Specify the deweighting spm folder, create one if it does not exist
    model_deweight_path=[out_path '/' model_deweight];
    if exist(model_deweight_path,'dir')~=7
        mkdir(model_deweight_path)
    end
    
    % Find folders in func
    CCN.functional_dirs='[subject]/[session]/func/[func_pattern]/';
    functional_dirs=expand_path(CCN.functional_dirs);

    %re-arrange functional_dirs so that run-01 is always before run-02
    %if they are the same task. This is only for ELP project. modified
    %1/7/2021
    func_dirs_rr=functional_dirs;
    for rr=1:length(functional_dirs)
        if rr<length(functional_dirs)
        [~, taskrunname1]=fileparts(fileparts(functional_dirs{rr}));
        sessionname1=taskrunname1(10:15);
        taskname1=taskrunname1(21:25);
        taskrun1=str2double(taskrunname1(end-5:end-5));
        [~, taskrunname2]=fileparts(fileparts(functional_dirs{rr+1}));
        sessionname2=taskrunname2(10:15);
        taskname2=taskrunname2(21:25);
        taskrun2=str2double(taskrunname2(end-5:end-5));
        if strcmp(sessionname1,sessionname2) && strcmp(taskname1,taskname2) && taskrun1>taskrun2
            func_dirs_rr{rr}=functional_dirs{rr+1};
            func_dirs_rr{rr+1}=functional_dirs{rr};
        end
        end
    end
    
    % Load the functional data, 6 mv parameters, and event onsets
    mv=[];
    swfunc=[];
    p=[];
    onsets=[];
    
    for j=1:length(func_dirs_rr)
         swfunc{j}=expand_path([func_dirs_rr{j} '[file]']);
        
        % Find events file
        if events_file_exist==1
            [p,run_n]=fileparts(func_dirs_rr{j}(1:end-1));
            event_file=[func_dirs_rr{j} run_n(1:end-4) 'events.tsv'];
        
        elseif events_file_exist==0
            [p,run_n]=fileparts(func_dirs_rr{j}(1:end-1));
            [q,session]=fileparts(fileparts(p));
            [~,this_subject]=fileparts(q);
            event_file=[bids_folder '/' this_subject '/' session '/func/' run_n(1:end-4) 'events.tsv'];
            
            rp_file=[p '/' run_n '/' CCN.rpfile run_n '.txt'];
        
        end
        
        % Read in events file and extract conditions
        event_data=tdfread(event_file);
        cond=unique(event_data.trial_type, 'row');
        [~,len]=size(cond);
        
        % Make sure datatypes are consistent
        if iscell(event_data.onset) || ischar(event_data.onset) || isstring(event_data.onset)
            event_data.onset = str2double(event_data.onset);
        end

        % Create a cell array with onsets for each condition
        for k=1:size(cond,1)  
            % Event_data.trial_type is a double array
            onsets{j}{k}=event_data.onset(event_data.trial_type==cond(k));
        end
        
        % Read in motion parameters
        mv{j}=load(rp_file);
        
    end
            
    % Pass the experimental design information to data
    data.swfunc=swfunc;
    data.conditions=conditions;
    data.onsets=onsets;
    data.dur=dur;
    data.mv=mv;
    
    % Run the firstlevel modeling and estimation (with deweighting)
    mat=firstlevel_4d(data, out_path, TR, model_deweight_path);
    origmat = [out_path '/SPM.mat'];

    % Run the contrasts
    contrast_f(origmat,contrasts,weights);
    contrast_f(mat,contrasts,weights);
    
catch e
    rethrow(e)
    %display the errors
end
disp("=====Job Complete=====")