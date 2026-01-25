function mni_coord = extract_MNIcoordinates(img_file)
%
% Extracts MNI coordinates from a binary mask

% Make sure datatypes are consistent
img_file = char(img_file);

% Read in mask file
img_info = spm_vol(img_file);
img      = spm_read_vols(img_info);  

% Extract mask indices
img_idx = find(img == 1);

% Convert linear indices back to voxel coordinates
[x, y, z] = ind2sub(size(img), img_idx);
voxel_coord = [x, y, z, ones(length(x), 1)];

% Convert voxel coordinates back to MNI coordinates
% For more information: https://nipy.org/nibabel/coordinate_systems.html
affine = img_info.mat;
mni_coord = affine * voxel_coord';
mni_coord = mni_coord(1:3, :)';