function [wfunc_file,wmeanfunc]=normalise_4d(cfunc_file,deformation,cmeanfunc_file)

cfunc_vols=[];
for i=1:length(cfunc_file)
    [other_p,other_n,other_e] = fileparts(char(cfunc_file{i}));
    cfunc_vols= [cfunc_vols; cellstr(spm_select('ExtFPList',other_p,['^' other_n other_e '$'],inf))];
end

%normalise all the functional images to MNI space
clear matlabbatch
matlabbatch{1}.spm.spatial.normalise.write.subj.def = {deformation};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = cfunc_vols;
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
    78 76 85];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;

%run the job
spm_jobman('run',matlabbatch)

%normalise the mean functional images to MNI space (for later coreg check)
clear matlabbatch
matlabbatch{1}.spm.spatial.normalise.write.subj.def = {deformation};
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {cmeanfunc_file};
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
    78 76 85];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;

%run the job
spm_jobman('run',matlabbatch)

%save the path of the normalised functional data
wfunc_file=[];
wfunc_file=cell(length(cfunc_file),1);
for i=1:length(cfunc_file)
    [wfunc_p,wfunc_n]=fileparts(char(cfunc_file{i}));
    wfunc_file{i}=[wfunc_p '/' insertBefore(wfunc_n,1,'w') '.nii'];
end
%save the path of normalised mean functional data
[mean_p,mean_n,mean_e]=fileparts(cmeanfunc_file);
wmeanfunc=[mean_p '/' insertBefore(mean_n,1,'w') mean_e];

