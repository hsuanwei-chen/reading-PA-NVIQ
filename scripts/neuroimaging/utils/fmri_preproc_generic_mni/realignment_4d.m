function [rfunc_file,meanfunc_file,rp_file] = realignment_4d(func_files,out_path)

% Expand func filenames. A single 4D Nifti file is expected per run. An
% SPM-style list of volumes is returned.
    func_vols=[];
for i=1:length(func_files)
    [func_p,func_n,func_e] = fileparts(char(func_files{i}));
    func_vols{i} = cellstr(spm_select('ExtFPList',func_p,['^' func_n func_e '$'],inf));
end

% SPM job
matlabbatch = [];
tag = 1;
matlabbatch{tag}.spm.spatial.realign.estwrite.data = func_vols;
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

% Commented out this part b/c it interferes with slurm
%matlabbatch{tag}.spm.util.print.fname = fullfile(out_path,'realignment.png');
%matlabbatch{tag}.spm.util.print.fig.figname = 'Graphics';
%matlabbatch{tag}.spm.util.print.opts = 'png';

%save(fullfile(func_p,'batch_realignment.mat'),'matlabbatch')
spm_jobman('run',matlabbatch)


% Filename of realignment params
rp_file=[];
for j=1:length(func_files)
    [func_p,func_n] = fileparts(char(func_files{j}));
    rp_file{j}= fullfile(func_p,['rp_' func_n '.txt']);
end

% Filenames for realigned images
[func_p,func_n] = fileparts(char(func_files{1}));
meanfunc_file = fullfile(func_p,['mean' func_n '.nii']);
rfunc_file = func_files;

