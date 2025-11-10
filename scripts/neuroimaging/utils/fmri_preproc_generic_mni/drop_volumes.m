function dfunc_file = drop_volumes(func_file,params)

% Drop initial volumes to account for saturation effects. Assumes 4D Nifti.

% Load images
[func_p,func_n,func_e] = fileparts(func_file);
P = spm_select('ExtFPList',func_p,['^' func_n func_e '$'],inf);
V = spm_vol(P);
Y = spm_read_vols(V);

% Drop initial volumes
keeps = (params.dropvols+1) : length(V) ;
outV = V(keeps);
outY = Y(:,:,:,keeps);

% Output filename and updated indices, and write
dfunc_file = fullfile(func_p,['d' func_n func_e]);
for v = 1:length(outV)
	outV(v).fname = dfunc_file;
	outV(v).n(1) = v;
	spm_write_vol(outV(v),outY(:,:,:,v));
end
