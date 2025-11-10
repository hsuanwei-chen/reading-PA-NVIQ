% function coreg_check( ...
%     bkgnd_file, ...
% 	out_path ...
%     )
function coreg_check(bkgnd_file,out_path,tpm)

% Make a nice at-a-glance image to check registration between structural
% and functional. Works great with the mean functional as the background
% and the gray matter segmented image as the overlay. Most consistent for
% checking if the MNI space versions are used.
%
% Dependencies:
%     canny  (http://www.mathworks.com/matlabcentral/fileexchange/45459-canny-edge-detection-in-2-d-and-3-d)
%
% Outputs:
%     edge image
%     png graphic

% Edge image filename
%overlay_file = [fileparts(which('spm')) '/tpm/TPM.nii'];
%overlay_file = [fileparts(which('spm')) '/toolbox/vbm8/Template_6_IXI550_MNI152.nii'];
[tpm_p, tpm_n, tpm_e]=fileparts(tpm);
overlay_file=[ tpm_p '/' tpm_n tpm_e];
%mask_file = [fileparts(which('spm')) '/tpm/mask_ICV.nii'];
mask_file=[fileparts(tpm) '/mask_ICV.nii'];
[~,n,e] = fileparts(overlay_file);
edge_file = fullfile(out_path,['edge_' n e]);

% Load the anat images
Vover = spm_vol([overlay_file ',1']);
Yover = spm_read_vols(Vover);
Vmask = spm_vol([mask_file ',1']);
Ymask = spm_read_vols(Vmask);
Yover(Ymask(:)==0) = 0;

% Compute the edge image and save
Yedge = canny(Yover);
Vedge = rmfield(Vover,'pinfo');
Vedge.fname = edge_file;
spm_write_vol(Vedge,Yedge);

% Show the functional image
spm_check_registration(bkgnd_file);

% Overlay the anat edge image
spm_orthviews('Xhairs','off');
spm_orthviews('addcolouredimage',1,edge_file,[1 0 0]);
spm_orthviews('Reposition',[0 0 0]);
[~,n] = fileparts(overlay_file);
title([n ' GM over subj mean func'])

% Print
print(gcf,'-dpng',fullfile(out_path,'coreg_check.png'))
