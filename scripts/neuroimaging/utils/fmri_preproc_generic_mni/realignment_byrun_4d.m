function [rfunc_file, rp_file] = realignment_byrun_4d(func_file,out_path)

% Expand func filenames. A single 4D Nifti file is expected per run. An
% SPM-style list of volumes is returned.
[func_p,func_n,func_e] = fileparts(func_file);
func_vols = cellstr(spm_select('ExtFPList',func_p,['^' func_n func_e '$'],inf));

% SPM job
matlabbatch = [];
tag = 1;
matlabbatch{tag}.spm.spatial.realign.estwrite.data = {func_vols};
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.sep = 4;
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.interp = 2;
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{tag}.spm.spatial.realign.estwrite.eoptions.weight = '';
matlabbatch{tag}.spm.spatial.realign.estwrite.roptions.which = [0 1];
matlabbatch{tag}.spm.spatial.realign.estwrite.roptions.interp = 4;
matlabbatch{tag}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
matlabbatch{tag}.spm.spatial.realign.estwrite.roptions.mask = 1;
matlabbatch{tag}.spm.spatial.realign.estwrite.roptions.prefix = 'r';

tag = tag + 1;
matlabbatch{tag}.spm.util.print.fname = fullfile(out_path, strcat(func_n, '_realignment.png'));
matlabbatch{tag}.spm.util.print.fig.figname = 'Graphics';
matlabbatch{tag}.spm.util.print.opts = 'png';

%save(fullfile(func_p,'batch_realignment.mat'),'matlabbatch')
spm_jobman('run',matlabbatch)

rfunc_file = func_file;
[file_p,file_n]=fileparts(func_file);
rp_file=[file_p '/rp_' file_n '.txt'];
