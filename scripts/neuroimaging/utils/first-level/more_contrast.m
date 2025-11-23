function contrast(mat,contrasts,weights, type)

matlabbatch=[];
matlabbatch{1}.spm.stats.con.spmmat = {mat};
for ii=1:length(contrasts)
matlabbatch{1}.spm.stats.con.consess{ii}.tcon.name = contrasts{ii};
matlabbatch{1}.spm.stats.con.consess{ii}.tcon.weights = weights{ii};
matlabbatch{1}.spm.stats.con.consess{ii}.tcon.sessrep = 'none';
end
matlabbatch{1}.spm.stats.con.delete = type;
%run the job
spm_jobman('run', matlabbatch);

end
