function multiple_regression(out_dirs,scans,covariates)

for ii=1:length(out_dirs)
    %model specification
    matlabbatch=[];
    matlabbatch{1}.spm.stats.factorial_design.dir = out_dirs(ii);
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = scans{ii};
    for jj=1:length(covariates.name)
        matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov(jj).c = covariates.values{jj};
        matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov(jj).cname = covariates.name{jj};
        matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov(jj).iCC = 1;
    end
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.incint = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    
    spm_jobman('run', matlabbatch);
    
    %model estimation
    mat=[out_dirs{ii} '/SPM.mat'];
    matlabbatch=[];
    matlabbatch{1}.spm.stats.fmri_est.spmmat = {mat};
    matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    
    spm_jobman('run',matlabbatch)
    
    %contrast manager
    [c_p,c_name]=fileparts(out_dirs{ii});
    matlabbatch=[];
    matlabbatch{1}.spm.stats.con.spmmat = {mat};
    for ii=1:length(covariates.name)+1
        weights=zeros(1,length(covariates.name)+1);
        weights(ii)=1;
        if ii==1
            matlabbatch{1}.spm.stats.con.consess{ii}.tcon.name = c_name;
        else
            matlabbatch{1}.spm.stats.con.consess{ii}.tcon.name = covariates.name{ii-1};
        end
        matlabbatch{1}.spm.stats.con.consess{ii}.tcon.weights = weights;
        matlabbatch{1}.spm.stats.con.consess{ii}.tcon.sessrep = 'none';
    end
    matlabbatch{1}.spm.stats.con.delete = 1;
    %run the job
    spm_jobman('run', matlabbatch);
    
end