function mat=firstlevel_4d(data, out_path, TR, model_deweight_path)

%%model specification
matlabbatch=[];
matlabbatch{1}.spm.stats.fmri_spec.dir = {out_path};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;

%define the data, conditions, onsets, durations
for jj=1:length(data.swfunc)
    [func_p, func_n, func_e]=fileparts(char(data.swfunc{jj}));
    func_vols=cellstr(spm_select('ExtFPList', func_p, ['^' func_n func_e '$'],inf));
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).scans =cellstr(func_vols);
    
    for ii=1:length(data.conditions{jj})
        matlabbatch{1}.spm.stats.fmri_spec.sess(jj).cond(ii).name = data.conditions{jj}{ii};
        matlabbatch{1}.spm.stats.fmri_spec.sess(jj).cond(ii).onset = data.onsets{jj}{:,ii};
        matlabbatch{1}.spm.stats.fmri_spec.sess(jj).cond(ii).duration = data.dur;
        matlabbatch{1}.spm.stats.fmri_spec.sess(jj).cond(ii).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess(jj).cond(ii).pmod = struct('name', {}, 'param', {}, 'poly', {});
        matlabbatch{1}.spm.stats.fmri_spec.sess(jj).cond(ii).orth = 1;
    end
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).multi = {''};
%    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(1).name = 'm1';
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(1).val = data.mv{jj}(:,1);
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(2).name = 'm2';
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(2).val = data.mv{jj}(:,2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(3).name = 'm3';
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(3).val = data.mv{jj}(:,3);
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(4).name = 'm4';
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(4).val = data.mv{jj}(:,4);
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(5).name = 'm5';
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(5).val = data.mv{jj}(:,5);
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(6).name = 'm6';
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).regress(6).val = data.mv{jj}(:,6);
    matlabbatch{1}.spm.stats.fmri_spec.sess(jj).hpf = 128;
end

matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0.5;
matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

%run the model specification
spm_jobman('run',matlabbatch)

%%model estimation
matlabbatch=[];
matlabbatch{1}.spm.stats.fmri_est.spmmat = {[out_path '/SPM.mat']};
matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;

%run model estimation
spm_jobman('run',matlabbatch)

%%re-run estimation to deweight the repaired images
%Art_redo.m to reweight the repaired images, which is a function in
%Art_Repair, modified by Jin Wang 3/1/2019
art_redo_jin(model_deweight_path);

mat=[model_deweight_path '/SPM.mat'];

end
