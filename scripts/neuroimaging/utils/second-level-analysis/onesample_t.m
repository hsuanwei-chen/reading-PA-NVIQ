function onesample_t(out_dirs,scans,covariates)

for ii=1:length(out_dirs)
    %model specification
    matlabbatch=[];
    matlabbatch{1}.spm.stats.factorial_design.dir = out_dirs(ii);
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = scans{ii};
    if ~isempty(covariates)
        for jj=1:length(covariates.name)
        matlabbatch{1}.spm.stats.factorial_design.cov(jj).c = covariates.values{jj};
        matlabbatch{1}.spm.stats.factorial_design.cov(jj).cname = covariates.name{jj};
        matlabbatch{1}.spm.stats.factorial_design.cov(jj).iCFI = 1;
        matlabbatch{1}.spm.stats.factorial_design.cov(jj).iCC = 1;
        end
    else
        matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    end
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
   
    spm_jobman('run',matlabbatch);
    
    %estimation of model
    mat=[out_dirs{ii} '/SPM.mat'];
    matlabbatch=[];
    matlabbatch{1}.spm.stats.fmri_est.spmmat = {mat};
    matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    
    spm_jobman('run',matlabbatch)
    
    %contrast
    [c_p,c_name]=fileparts(out_dirs{ii});
    if isempty(covariates)
        weights=[1];
    else
    weights=[1 zeros(1,length(covariates.name))];
    end
    matlabbatch=[];
    matlabbatch{1}.spm.stats.con.spmmat = {mat};
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = c_name;
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = weights;
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.delete = 1;
    %run the job
    spm_jobman('run', matlabbatch);
    
end

end
