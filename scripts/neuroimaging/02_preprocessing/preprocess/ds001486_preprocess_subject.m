%% Preprocessing Data for Older Children (no multi-band)
% This script was created by Professor Baxter Rogeres (VUIIS), but is
% heavily modified based on our lab pipeline by Jin Wang updated 1/5/2021
% (1) realignment to mean, reslice the mean.
% (2) segment anatomical image to TPM template. We get a deformation file "y_filename" and this is used in normalisation step to normalize all the
%     functional data and the mean functional data.
% (3) Then we make a skull-striped anatomical T1 (based on segmentation) and coregister mean functional data (and all other functional data) to the anatomical T1.
% (4) Smoothing.
% (5) Art_global. It calls the realignmentfile (the rp_*.txt) to do the interpolation. This step identifies the bad volumes(by setting scan-to-scan movement
%     mv_thresh =1.5mm and global signal intensity deviation Percent_thresh= 4 percent, any volumes movement to reference volume, which is the mean, >5mm) and repair
%     them with interpolation. This step uses art-repair art_global.m function (the subfunctions within it are art_repairvol, which does repairment, and art_climvmnt, which identifies volumes movment to reference.
% (6) We use check_reg.m to see how well the meanfunctional data was normalized to template by visual check.

%% Last modified: 2025/11/18
% 2025/11/18 IC: updated with new motion criteria
% 2025/03/31 IC: updated filepaths for R9 environment and catch missing runs
% 2025/01/23 IC: Updated filepaths and reorganzied script to improve readability

function ds001486_preprocess_subject(subjects)
%% Specify filepaths
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

% Define path to template brain
tpm= fullfile(spm_path, 'tpm', 'TPM.nii');

%% Define data folder and file parameters for preprocessing
% Create structure CCN
global CCN;

% Define folder with preprocessed data
% Define dataset
% Define time point
% Define Functional folder name pattern
% Define Functional data name pattern
% Define Anatomical data name pattern
CCN.preprocessed_folder = 'data/neuroimaging/preprocessed';
CCN.dataset = 'ds001486';
CCN.session = 'ses-T1';
CCN.func_folder = 'sub*';
CCN.func_pattern = 'sub*.nii';
CCN.anat_pattern = 'sub*_T1w*.nii';
CCN.output_folder = 'figures';

%% Preprocessing
% If you do slice-timing, please enter the following parameters
tr = 2;
% There are four options:    
%   'ascending': 1:nslices;
%   'descending':nslices:-1:1
%   'ascending_interleaved_odd': [1:2:nslices 2:2:nslices]
%   'ascending_interleaved_even': [2:2:nslices 1:2:nslices]
%   'descending_interleaved': [nslices:-2:1 (nslices-1):-2:1]
slorder = 'ascending_interleaved_even' ;

% Initialize
spm('defaults','fmri');
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);
%spm_figure('Create', 'Graphics', 'Graphics');

% Dependency and sanity checks
% Check matlab version
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
    fprintf('Pre-processing %s_%s ...\n', CCN.dataset, subjects); 
    
    % Define subjects folder
    CCN.subj_folder = [proj_dir '/' CCN.preprocessed_folder '/' CCN.dataset '/' subjects];

    % Find all functional scans
    CCN.func_f='[subj_folder]/[session]/func/[func_folder]/';
    func_f=expand_path(CCN.func_f);
    func_files=[];
    
    for m=1:length(func_f)
        func_files{m}=expand_path([func_f{m} '[func_pattern]']);
    end
    
    % Find anatomical scans
    CCN.anat='[subj_folder]/[session]/anat/[anat_pattern]';
    anat_file=char(expand_path(CCN.anat));

    % Create folder to save motion QC figures
    out_path = [CCN.subj_folder '/' CCN.output_folder];
    if ~exist(out_path)
        mkdir(out_path)
    end

    % Clean up txt files from motion QC
    txt_file = dir([CCN.subj_folder '/' CCN.session '/func/*/*.txt']);
    for f=1:length(txt_file)
        delete(fullfile(txt_file(f).folder, txt_file(f).name));
    end

    % Processing params
    params = struct( ...
        'tr', tr, ...
        'slorder', slorder ...
    );
    % %'dropvols', dropvols, ...
    % % Drop volumes
    % dfunc_file = drop_volumes(func_file,params);

    % Slice timing correction
    afunc_file=slice_timing_correction_4d(func_files,params);

    % Motion correction
    [rfunc_file,meanfunc_file,rp_file]=realignment_4d(afunc_file, out_path);

    %Segmentation, it will write a deformation file "y_"filename.
    [deformation,seg_files]=segmentation(anat_file,tpm);
    
    %Make a no-skull T1 image from segmented product(combine
    %grey,white,csf as a mask and then apply it to T1).
    mask=mkmask(seg_files);
    anat_nn='T1_ns';
    anat_ns=no_skull(anat_file,mask,anat_nn);
    
    % Coregister to T1
    % [cmeanfunc_file,cfunc_file] = coregister( ...
    %     meanfunc_file, anat_file, filt_a, rfunc_file, out_path, 'no');
    [cmeanfunc_file,cfunc_file]=coregister_4d(meanfunc_file, anat_ns, afunc_file, out_path, 'no');
    
    %Normalise, it will add a w to the files
    %[wfunc_file]=normalise(cfunc_file,deformation);
    [wfunc_file,wmeanfunc]=normalise_4d(cfunc_file,deformation,cmeanfunc_file);
    
    % Spatial smoothing
    fwhm=6;
    swfunc_file=smoothing_4d(wfunc_file,fwhm);
    
    %Art_global (identify bad volumes and repair them using interpolation), it
    %will add a v to the files. In this art_global_jin, the
    %art_clipmvmt is the movement of all images to reference.
    Percent_thresh=4; %global signal intensity change
    mv_thresh=1.5; % scan-to-scan movement
    MVMTTHRESHOLD=100; % movement to reference,see in art_clipmvmt
    
    for ii=1:length(swfunc_file)
        [swfunc_p,swfunc_n,swfunc_e]=fileparts(char(swfunc_file{ii}));
        swfunc_vols=cellstr(spm_select('ExtFPList',swfunc_p,['^' swfunc_n swfunc_e '$'],inf));
        art_global_jin(char(swfunc_vols),rp_file{ii},4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD);
    end
    
    % Coreg check
    %coreg_check(wmeanfunc, out_path, tpm);
        
catch e
    rethrow(e)
    %display the errors
end
disp("=====Job Complete=====")