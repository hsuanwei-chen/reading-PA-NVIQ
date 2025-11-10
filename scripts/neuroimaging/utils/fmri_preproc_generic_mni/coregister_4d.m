function [c_source_file,c_other_file] = coregister_4d(source_file, target_file, other_file, out_path, com_flag)

% Source and target should be a single volume (3D). Other can be a 4D file
% which will be expanded.

matlabbatch = [];
tag = 0;
	
%Expand "other" filenames
other_vols=[];
for i=1:length(other_file)
[other_p,other_n,other_e] = fileparts(char(other_file{i}));
other_vols = [other_vols; cellstr(spm_select('ExtFPList',other_p,['^' other_n other_e '$'],inf))];
end

% Shift center of mass if requested 
if strcmp('yes',com_flag)
	
	% Image centers of mass
	target_com = find_center_of_mass(target_file);
	source_com = find_center_of_mass(source_file);
	
	% How to move the source image
	source_shift = target_com - source_com;
	source_shift_matrix = spm_matrix(source_shift);
	
	% Move via batch reorient
	tag = tag + 1;
	matlabbatch{tag}.spm.util.reorient.srcfiles = other_vols;
	matlabbatch{tag}.spm.util.reorient.transform.transM = source_shift_matrix;
	matlabbatch{tag}.spm.util.reorient.prefix = 'c';
	
	tag = tag + 1;
	matlabbatch{tag}.spm.util.reorient.srcfiles = {source_file};
	matlabbatch{tag}.spm.util.reorient.transform.transM = source_shift_matrix;
	matlabbatch{tag}.spm.util.reorient.prefix = 'c';
	
	% Get filenames for reoriented images
	[source_p,source_n,source_e] = fileparts(source_file);
	c_source_file = fullfile(source_p,['c' source_n source_e]);
	c_other_file = fullfile(other_p,['c' other_n other_e]);
	c_other_vols = other_vols;
	for f = 1:length(c_other_vols)
		[p,n,e,k] = spm_fileparts(other_vols{f});
		c_other_vols{f} = fullfile(p,['c' n e k]);
	end
	
else

	% No COM shift
	c_source_file = source_file;
	c_other_file = other_file;
	c_other_vols = other_vols;

end


% Coregister
tag = tag + 1;
matlabbatch{tag}.spm.spatial.coreg.estimate.ref = {target_file}; %
matlabbatch{tag}.spm.spatial.coreg.estimate.source = {c_source_file}; % 
matlabbatch{tag}.spm.spatial.coreg.estimate.other = c_other_vols;
matlabbatch{tag}.spm.spatial.coreg.estimate.eoptions = struct( ...
    'cost_fun', 'nmi', ...
    'sep', [4 2], ...
	'tol', [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001], ...
    'fwhm', [7 7] );

tag = tag + 1;

% Commented out this part b/c it interferes with slurm
%matlabbatch{tag}.spm.util.print.fname = fullfile(out_path,'coregister.png');
%matlabbatch{tag}.spm.util.print.fig.figname = 'Graphics';
%matlabbatch{tag}.spm.util.print.opts = 'png';

% Run
%save(fullfile(source_p,'batch_coregister.mat'),'matlabbatch')
spm_jobman('run',matlabbatch)
