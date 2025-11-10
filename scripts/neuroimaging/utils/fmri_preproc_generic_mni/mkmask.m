function mask=mkmask(seg_files)
out=fileparts(seg_files{1});

matlabbatch=[];
matlabbatch{1}.spm.util.imcalc.input = seg_files;
matlabbatch{1}.spm.util.imcalc.output = 'mask';
matlabbatch{1}.spm.util.imcalc.outdir = {out};
matlabbatch{1}.spm.util.imcalc.expression = 'i1+i2+i3';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;

spm_jobman('run',matlabbatch)

mask=[out '/mask.nii'];