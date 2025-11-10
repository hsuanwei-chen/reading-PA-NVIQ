function anat_ns=no_skull(anat_file,mask,anat_nn)

target_file{1,:}=[anat_file ',1']; 
target_file{2,:}=[mask, ',1'];
out=fileparts(anat_file);

matlabbatch=[];
matlabbatch{1}.spm.util.imcalc.input = target_file;
matlabbatch{1}.spm.util.imcalc.output = anat_nn;
matlabbatch{1}.spm.util.imcalc.outdir = {out};
matlabbatch{1}.spm.util.imcalc.expression = 'i1.*(i2>0)';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

spm_jobman('run',matlabbatch)

anat_ns=[out '/' anat_nn '.nii'];