function extract_topBetas(con_map_file, roi_file, output_dir, output_prefix, top_n)
%
% Extracts the top N voxels from an individual-level contrast map
% and creates:
%   (1) a mask NIfTI with top N voxels = 1, others = 0
%   (2) a csv file listing the voxel indices and beta values
%
% Inputs:
%   con_map_file  : path to contrast NIfTI (e.g., 'con_0001.nii')
%   roi_file      : path to ROI NIfTI (e.g. 'STG.nii')
%   output_dir    : path to directory for saving top voxel results
%   output_prefix : prefix for outputs (e.g. 'sub-01_top1000')
%   n_topVoxels   : number of voxels to keep (e.g. 1000)

% Make sure datatypes are consistent
con_map_file = char(con_map_file);
roi_file = char(roi_file);

% Set output file names
roi_betas_csv = fullfile(output_dir, sprintf("%s_Betas.csv", output_prefix));
top_roi_betas_csv = fullfile(output_dir, sprintf("%s_top%iBetas.csv", output_prefix, top_n));

% Read in contrast map
con_map_info = spm_vol(con_map_file);
con_map_img  = spm_read_vols(con_map_info);  

% Read in ROI file
roi_info = spm_vol(roi_file);
roi_img  = spm_read_vols(roi_info);  

% Check dimensions
if ~isequal(size(roi_img), size(roi_img))
    error('Dimensions of ROI does does not match t-statistic map')
end

% Extract ROI indices and corresponding beta
roi_idx = find(roi_img == 1);
roi_betas = [roi_idx, con_map_img(roi_idx)];

% Convert linear indices back to voxel coordinates
[x, y, z] = ind2sub(size(roi_img), roi_idx);
voxel_coord = [x, y, z, ones(length(x), 1)];

% Convert voxel coordinates back to MNI coordinates
% For more information: https://nipy.org/nibabel/coordinate_systems.html
affine = roi_info.mat;
mni_coord = affine * voxel_coord';

% Combine MNI coordinates with their associated value
roi_betas = [roi_betas(:,1), mni_coord', roi_betas(:, 2)];

% Extract top N voxels
roi_betas_idx = ~isnan(roi_betas(:, 6)); 
roi_betas_descend = sortrows(roi_betas(roi_betas_idx, :), 6, "descend");
top_roi_betas = roi_betas_descend(1:top_n, :);

% Save betas and betas_top as csv files
tbl_roi_betas = array2table(roi_betas);
tbl_roi_betas.Properties.VariableNames = {'Idx', 'MNI_X', 'MNI_Y', 'MNI_Z', 'Translation', 'Value'};
writetable(tbl_roi_betas, roi_betas_csv)

tbl_top_roi_betas = array2table(top_roi_betas);
tbl_top_roi_betas.Properties.VariableNames = {'Idx', 'MNI_X', 'MNI_Y', 'MNI_Z', 'Translation', 'Value'};
writetable(tbl_top_roi_betas, top_roi_betas_csv)

% Create mask of top N voxels
mask_top_roi_betas = zeros(size(con_map_img));
mask_top_roi_betas(top_roi_betas(:, 1)) = 1;

% Set mask header information
mask_hdr = con_map_info;
mask_hdr.fname = char(fullfile(output_dir, sprintf('%s_top%iBeta_mask.nii', output_prefix, top_n)));
mask_hdr.descrip = sprintf('Top %i betas from %s', top_n, roi_file);

% Write mask into 3D image
spm_write_vol(mask_hdr, mask_top_roi_betas);

end