function s_file = smoothing_4d(wfunc_file,fwhm)

wfunc_vols=[];
for i=1:length(wfunc_file)
    [other_p,other_n,other_e] = fileparts(char(wfunc_file{i}));
    wfunc_vols= [wfunc_vols; cellstr(spm_select('ExtFPList',other_p,['^' other_n other_e '$'],inf))];
end

clear matlabbatch
matlabbatch{1}.spm.spatial.smooth.data = wfunc_vols;
matlabbatch{1}.spm.spatial.smooth.fwhm = [fwhm fwhm fwhm];
matlabbatch{1}.spm.spatial.smooth.dtype = spm_type('float32'); %what is this? The default is 0
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = sprintf('s%d_',fwhm);
spm_jobman('run',matlabbatch)

% [p,n,e] = fileparts(file);
% s_file = fullfile(p,[matlabbatch{1}.spm.spatial.smooth.prefix n e]);

%save the path of the normalised functional data 
s_file=[];
s_file=cell(length(wfunc_file),1);
for i=1:length(wfunc_file)
    [sfunc_p,sfunc_n,sfunc_e]=fileparts(char(wfunc_file{i}));
    s_file{i}=[sfunc_p '/' insertBefore(sfunc_n,1,matlabbatch{1}.spm.spatial.smooth.prefix) sfunc_e];
end
