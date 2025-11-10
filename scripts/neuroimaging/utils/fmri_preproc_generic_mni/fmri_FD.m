function FD = fmri_FD(rp_file)
%Function to calculate Framewise Displacement (FD) (Power et al., 2012)from
%the six realignment parameters.  FD is calculated by summing the absolute
%value of the differenced (time t?time t?1) translational realignment
%parameters and the three differenced rotational parameters, which are
%converted from radians to millimeters by assuming a brain radius of 50 mm.
%
%Usage: FD = fmri_FD(rp_file)
%where  rp_file is the path/file name containing the realignment parameters
%       in columns (such as what is obtained from spm_realign or mcflirt)

dat = load(rp_file); %Load motion parameter file
dat = dat(:, 1:6); %Only include columns 1-6
order = 1;
diff_dat = abs([[0 0 0 0 0 0]; diff(dat, order, 1)]); %Takes the difference of the val

% 	Multiply by 50mm brain;
diff_dat(:,4:6) = diff_dat(:,4:6) * 50;
FD = sum(diff_dat, 2);

end