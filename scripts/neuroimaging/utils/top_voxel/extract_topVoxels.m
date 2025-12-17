function extract_topVoxels(tmap_file, roi_file, output_dir, output_prefix, top_n)
%
% Extracts the top N voxels from an individual-level t-statistic map
% and creates:
%   (1) a mask NIfTI with top N voxels = 1, others = 0
%   (2) a text file listing the voxel indices and t-values
%
% Inputs:
%   tmap_file     : path to t-statistic NIfTI (e.g., 'spmT_0001.nii')
%   roi_file      : path to ROI NIfTI (e.g. 'STG.nii')
%   output_dir    : path to directory for saving top voxel results
%   output_prefix : prefix for outputs (e.g. 'sub-01_top1000')
%   n_topVoxels   : number of voxels to keep (e.g. 1000)

% Make sure datatypes are consistent
tmap_file = char(tmap_file);
roi_file = char(roi_file);

% Set output file names
roi_tvals_csv = fullfile(output_dir, sprintf("%s_Tvalues.csv", output_prefix));
top_roi_tvals_csv = fullfile(output_dir, sprintf("%s_top%i_Tvalues.csv", output_prefix, top_n));

% Read in t-statistic map
tmap_info = spm_vol(tmap_file);
tmap_img  = spm_read_vols(tmap_info);  

% Read in ROI file
roi_info = spm_vol(roi_file);
roi_img  = spm_read_vols(roi_info);  

% Check dimensions
if ~isequal(size(roi_img), size(roi_img))
    error('Dimensions of ROI does does not match t-statistic map')
end

% Extract ROI indices and corresponding t-value
roi_idx = find(roi_img == 1);
roi_tvals = [roi_idx, tmap_img(roi_idx)];

% Convert linear indices back to voxel coordinates
[x, y, z] = ind2sub(size(roi_img), roi_idx);
voxel_coord = [x, y, z, ones(length(x), 1)];

% Convert voxel coordinates back to MNI coordinates
% For more information: https://nipy.org/nibabel/coordinate_systems.html
affine = roi_info.mat;
mni_coord = affine * voxel_coord';

% Combine MNI coordinates with their associated value
roi_tvals = [roi_tvals(:,1), mni_coord', roi_tvals(:, 2)];

% Extract top N voxels
roi_tvals_descend = sortrows(roi_tvals, 6, "descend");
top_roi_tvals = roi_tvals_descend(1:top_n, :);

% Save tvals and tvals_top as csv files
tbl_roi_tvals = array2table(roi_tvals);
tbl_roi_tvals.Properties.VariableNames = {'Idx', 'MNI_X', 'MNI_Y', 'MNI_Z', 'Translation', 'Value'};
writetable(tbl_roi_tvals, roi_tvals_csv)

tbl_top_roi_tvals = array2table(top_roi_tvals);
tbl_top_roi_tvals.Properties.VariableNames = {'Idx', 'MNI_X', 'MNI_Y', 'MNI_Z', 'Translation', 'Value'};
writetable(tbl_top_roi_tvals, top_roi_tvals_csv)

% Create mask of top N voxels
mask_top_roi_tvals= zeros(size(tmap_img));
mask_top_roi_tvals(top_roi_tvals(:, 1)) = 1;

% Set mask header information
mask_hdr = tmap_info;
mask_hdr.fname = char(fullfile(output_dir, sprintf('%s_top%i_mask.nii', output_prefix, top_n)));
mask_hdr.descrip = sprintf('Top %i voxels from %s', top_n, roi_file);

% Write mask into 3D image
spm_write_vol(mask_hdr, mask_top_roi_tvals);

end