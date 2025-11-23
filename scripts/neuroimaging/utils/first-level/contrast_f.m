function contrast(mat,contrasts,weights)

matlabbatch=[];
matlabbatch{1}.spm.stats.con.spmmat = {mat};
for ii=1:length(contrasts)
matlabbatch{1}.spm.stats.con.consess{ii}.tcon.name = contrasts{ii};
matlabbatch{1}.spm.stats.con.consess{ii}.tcon.weights = weights{ii};
matlabbatch{1}.spm.stats.con.consess{ii}.tcon.sessrep = 'none';
end
matlabbatch{1}.spm.stats.con.delete = 1;
%run the job
spm_jobman('run', matlabbatch);

end
