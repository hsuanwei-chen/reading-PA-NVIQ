%% Generic fMRI preprocessing
%
% Scan spider applicable to most fMRI.
%
% Performs:
%     Drop initial volumes if requested
%     Slice timing correction
%     Motion correction
%     Coregistration to T1 anatomical
%     Transform to MNI space using specified warp from the T1
%     Spatial smoothing


%% DEPENDENCIES
%     Matlab 2013+
%     SPM12 r 6225 with VBM8 r435
%     ImageMagick


%% INPUTS

% Path: to local code directory
code_path = [udir '/masimatlab/trunk/xnatspiders/matlab/fmri_preproc_generic_mni'];

% Path: to SPM12r6225
spm_path = [udir '/Dropbox/matlab/softwareinstallations/spm12r6225_with_vbm8r435'];

% Path: To ImageMagick
imagemagick_path = '/usr/local/bin';

% Path: where output will be stored
out_path = [testdir '/output'];

% File: From XNAT. High res anatomical image
%    Typically NIFTI of a T1 scan.
anat_file = [testdir filesep 'anat.nii'];

% File: From XNAT. MNI space deformation field
%    Typically DEF_FWD of NDW_VBM associated with the T1. Filename must
%    begin with 'y_' or we get incomprehensible errors from SPM.
deffwd_file = [testdir '/y_deffwd.nii'];

% File: From XNAT. Native space gray matter image
%    Typically GRAY of NDW_VBM associated with the T1.
gray_file = [testdir '/p1.nii'];

% File: From XNAT. Native space white matter image
%    Typically WHITE of NDW_VBM associated with the T1.
white_file = [testdir '/p2.nii'];

% File: From XNAT. Native space CSF image
%    Typically CSF of NDW_VBM associated with the T1.
csf_file = [testdir '/p3.nii'];

% File: From XNAT. Functional images series
%    Typically NIFTI of the fMRI scan we are processing.
func_file = [testdir filesep 'func.nii'];

% Variables: From XNAT. Scan-specific parameters that should be stored as
% variables with the functional image in XNAT and read from there. They
% should not be hard coded in the processor - spider should fail if they
% aren't available. Slice order options are:
%       'ascending'
%       'descending'
%       'ascending_interleaved'
%       'descending_interleaved'
%       'none' or ''
tr = 2000;  % TR in msec
dropvols = 0;  % Number of initial volumes to discard
slorder = 'none';  % Slice acq order



%% PROCESSING
addpath(genpath(code_path))
main( ...
	spm_path, ...
	imagemagick_path, ...
	out_path, ...
	anat_file, ...
	deffwd_file, ...
    gray_file, ...
    white_file, ...
    csf_file, ...
	func_file, ...
	tr, ...
	dropvols, ...
	slorder ...
	);

%% OUTPUTS

% PDF
% fmri_preproc.pdf

% PARAMS
% params.txt

% RP_TXT
% rp_ad<func_file>.txt

% WMEANFMRI
% wmeanad<func_file>.nii

% WFMRI
% wad<func_file>.nii

% SWFMRI
% s6_wad<func_file>.nii

% WGRAY
% w<gray_file>.nii

% WWHITE
% w<white_file>.nii

% WCSF
% w<csf_file>.nii

