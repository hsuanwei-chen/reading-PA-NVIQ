%% Set filepaths;
clear;clc

% Define dataset, top number of voxels
dataset = 'ds001486';

% Define directories
root_dir = '/panfs/accrepfs.vampire/data/booth_lab';
proj_dir = fullfile(root_dir, 'Isaac', '01_project', 'reading-PA-NVIQ');
data_dir = fullfile(proj_dir, "data", "neuroimaging", "preprocessed", dataset);
util_dir = fullfile(proj_dir, 'scripts', 'neuroimaging', 'utils');
spm_dir  = fullfile(root_dir, 'LabCode', 'typical_data_analysis', 'spm12'); 

% Add directories to search path
addpath(genpath(util_dir));
addpath(genpath(spm_dir));

% Define subject file
subj_dir = fullfile(data_dir, 'sub-013', 'ses-T1', 'func', 'sub-013_ses-T1_task-Rhyming_bold');
swfunc_file = fullfile(subj_dir, 's6_wasub-013_ses-T1_task-Rhyming_bold.nii');
[swfunc_p,swfunc_n,swfunc_e]=fileparts(char(swfunc_file));
swfunc_vols=cellstr(spm_select('ExtFPList',swfunc_p,['^' swfunc_n swfunc_e '$'],inf));

%% Set art_global input parameters
Images = char(swfunc_vols);
RealignmentFile = fullfile(subj_dir, 'rp_asub-013_ses-T1_task-Rhyming_bold.txt');
HeadMaskType = 4;
RepairType = 1;

%art_clipmvmt is the movement of all images to reference.
Percent_thresh=4; %global signal intensity change
mv_thresh=1.5; % scan-to-scan movement
MVMTTHRESHOLD=100; % movement to reference,see in art_clipmvmt

%art_global_jin(Images,RealignmentFile,4,1,Percent_thresh,mv_thresh,MVMTTHRESHOLD)

%% Run art_global
% -----------------------
% Initialize, begin loop
% -----------------------
pfig = [];
% Configure while preserving old SPM versions
spmv = spm('Ver'); spm_ver = 'spm5';  

% ------------------------
% Collect files
% ------------------------
num_sess = size(RealignmentFile,1);
global_type_flag = HeadMaskType;
realignfile = 1;
P{1} = Images;
M = [];

for i = 1:num_sess
    %P{i} = Images{i};
    mvmt_file = char(RealignmentFile(i,:));
    M{i} = load(mvmt_file);
    %[mv_path,mv_name,mv_ext] = fileparts(mvmt_file);
    % M{1} = mv_data;
end

repair1_flag = 0;   % Only repair scan 1 when necessary
%repair1_flag = 1;   % Force repair scan 1  (Reisslab)
GoRepair = 1;       % Automatic Repair

if global_type_flag == 4   %  Automask option
    disp('Generated mask image is written to file ArtifactMask.img.')
    Pnames = P{1};
    Automask = art_automask(Pnames(1,:),-1,1);
    maskcount = sum(sum(sum(Automask)));  %  Number of voxels in mask.
    voxelcount = prod(size(Automask));    %  Number of voxels in 3D volume.
end
spm_input('!DeleteInputObj');

P = char(P);

mv_data = [];
for i = 1:length(M)
    mv_data = vertcat(mv_data,M{i});
end

% -------------------------
% get file identifiers and Global values
% -------------------------
fprintf('%-4s: ','Mapping files...')                                  
VY     = spm_vol(P);
fprintf('%3s\n','...done')                                          

temp = any(diff(cat(1,VY.dim),1,1),1);
if strcmp(spm_ver,'spm5')
     % or could test length(temp) == 3
     if ~isempty(find(diff(cat(1,VY.dim)) ~= 0 ))   
 	    error('images do not all have the same dimensions (SPM5)')
     end
elseif length(temp) == 4       % SPM2 case
     if any(any(diff(cat(1,VY.dim),1,1),1)&[1,1,1,0])
         error('images do not all have the same dimensions')
     end
end
nscans = size(P,1);

% ------------------------
% Compute Global variate
%--------------------------
%GM     = 100;
g      = zeros(nscans,1);
fprintf('%-4s: %3s','Calculating globals...',' ')
for i = 1:nscans
    Y = spm_read_vols(VY(i));
    Y = Y.*Automask;
    if realignfile == 0
        output = art_centroid(Y);
        centroiddata(i,1:3) = output(2:4);
        g(i) = output(1)*voxelcount/maskcount;
    else     % realignfile == 1
        g(i) = mean(mean(mean(Y)))*voxelcount/maskcount;
    end
end

% Convert rotation movement to degrees
mv_data(:,4:6)= mv_data(:,4:6)*180/pi; 
if global_type_flag==4
    fprintf('\n%g voxels were in the auto generated mask.\n', maskcount)
end

% ------------------------
% Compute default out indices by z-score, or by Percent-level is std is small.
% ------------------------ 
%  Consider values > Percent_thresh as outliers (instead of z_thresh*gsigma) if std is small.
gsigma = std(g);
gmean = mean(g);
pctmap = 100*gsigma/gmean;
mincount = Percent_thresh*gmean/100;
%z_thresh = max(z_thresh, mincount/gsigma );
z_thresh = mincount/gsigma;        % Default value is PercentThresh.
z_thresh = 0.1*round(z_thresh*10); % Round to nearest 0.1 Z-score value
zscoreA = (g - mean(g))./std(g);  % in case Matlab zscore is not available
glout_idx = (find(abs(zscoreA) > z_thresh))';

% ------------------------
% Compute default out indices from rapid movement
% ------------------------ 
% Rotation measure assumes voxel is 65 mm from origin of rotation.
if realignfile == 1 | realignfile == 0
    delta = zeros(nscans,1);  % Mean square displacement in two scans
    for i = 2:nscans
        delta(i,1) = (mv_data(i-1,1) - mv_data(i,1))^2 +...
                (mv_data(i-1,2) - mv_data(i,2))^2 +...
                (mv_data(i-1,3) - mv_data(i,3))^2 +...
                1.28*(mv_data(i-1,4) - mv_data(i,4))^2 +...
                1.28*(mv_data(i-1,5) - mv_data(i,5))^2 +...
                1.28*(mv_data(i-1,6) - mv_data(i,6))^2;
        delta(i,1) = sqrt(delta(i,1));
    end
end

 % Also name the scans before the big motions (v2.2 fix)
deltaw = zeros(nscans,1);
for i = 1:nscans-1
    deltaw(i) = max(delta(i), delta(i+1));
end
delta(1:nscans-1,1) = deltaw(1:nscans-1,1);

% Adapt the threshold  (v2.3 fix)
if RepairType == 2 | GoRepair == 4
    delsort = sort(delta);
    if delsort(round(0.75*nscans)) > mv_thresh
        mv_thresh = min(1.0,delsort(round(0.75*nscans)));
        words = ['Automatic adjustment of movement threshold to ' num2str(mv_thresh)];
        disp(words)
        Percent_thresh = mv_thresh + 0.8;    % v2.4
    end
end

mvout_idx = find(delta > mv_thresh)';

% Total repair list
out_idx = unique([mvout_idx glout_idx]);
if repair1_flag == 1
    out_idx = unique([ 1 out_idx]);
end
% Initial deweight list before margins
outdw_idx = out_idx; 
% Initial clip list without removing large displacements
clipout_idx = out_idx;

% -----------------------
% Draw initial figure
% -----------------------

figure('Units', 'normalized', 'Position', [0.2 0.2 0.6 0.7]);
rng = max(g) - min(g);   % was range(g);
pfig = gcf;

subplot(5,1,1);
plot(g);
%xlabel(['artifact index list [' int2str(out_idx') ']'], 'FontSize', 8, 'Color','r');
%ylabel(['Range = ' num2str(rng)], 'FontSize', 8);
ylabel('Global Avg. Signal');
xlabel('Red vertical lines are to depair. Green vertical lines are to deweight.');
title('ArtifactRepair GUI to repair outliers and identify scans to deweight');

% Add vertical exclusion lines to the global intensity plot
axes_lim = get(gca, 'YLim');
axes_height = [axes_lim(1) axes_lim(2)];
for i = 1:length(outdw_idx)   % Scans to be Deweighted
    line((outdw_idx(i)*ones(1, 2)), axes_height, 'Color', 'g');
end

subplot(5,1,2);
%thresh_axes = gca;
%set(gca, 'Tag', 'threshaxes');
zscoreA = (g - mean(g))./std(g);  % in case Matlab zscore is not available
plot(abs(zscoreA));
ylabel('Std away from mean');
xlabel('Scan Number  -  horizontal axis for all plots');

thresh_x = 1:nscans;
thresh_y = z_thresh*ones(1,nscans);
line(thresh_x, thresh_y, 'Color', 'r');

%  Mark global intensity outlier images with vertical lines
axes_lim = get(gca, 'YLim');
axes_height = [axes_lim(1) axes_lim(2)];
for i = 1:length(glout_idx)
    line((glout_idx(i)*ones(1, 2)), axes_height, 'Color', 'r');
end

subplot(5,1,3);
xa = [ 1:nscans];
plot(xa,mv_data(:,1),'b-',xa,mv_data(:,2),'g-',xa,mv_data(:,3),'r-',...
   xa,mv_data(:,4),'r--',xa,mv_data(:,5),'b--',xa,mv_data(:,6),'g--');
%plot(,'--');
ylabel('ReAlignment');
xlabel('Translation (mm) solid lines, Rotation (deg) dashed lines');
%legend('x mvmt', 'y mvmt', 'z mvmt','pitch','roll','yaw',0);
legend('x mvmt', 'y mvmt', 'z mvmt','pitch','roll','yaw');
h = gca;
set(h,'Ygrid','on');

subplot(5,1,4);   % Rapid movement plot
plot(delta);
ylabel('Motion (mm/TR)');
xlabel('Scan to scan movement (~mm). Rotation assumes 65 mm from origin');
y_lim = get(gca, 'YLim');
% legend('Fast motion',0);
legend('Fast motion');
h = gca;
set(h,'Ygrid','on');

thresh_x = 1:nscans;
thresh_y = mv_thresh*ones(1,nscans);
line(thresh_x, thresh_y, 'Color', 'r');
   
% Mark all movement outliers with vertical lines
subplot(5,1,4)
axes_lim = get(gca, 'YLim');
axes_height = [axes_lim(1) axes_lim(2)];
for i = 1:length(mvout_idx)
    line((mvout_idx(i)*ones(1,2)), axes_height, 'Color', 'r');
end

%keyboard;
h_rangetext = uicontrol(gcf, 'Units', 'characters', 'Position', [10 10 18 2],...
        'String', 'StdDev of data is: ', 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8]);
h_rangenum = uicontrol(gcf, 'Units', 'characters', 'Position', [29 10 10 2], ...
        'String', num2str(gsigma), 'Style', 'text', ...
        'HorizontalAlignment', 'left',...
        'Tag', 'rangenum',...
        'BackgroundColor', [0.8 0.8 0.8]);
h_threshtext = uicontrol(gcf, 'Units', 'characters', 'Position', [25 8 16 2],...
        'String', 'Current threshold (std devs):', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
h_threshnum = uicontrol(gcf, 'Units', 'characters', 'Position', [44 8 10 2],...
        'String', num2str(z_thresh), 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8],...
        'Tag', 'threshnum');
h_threshmvtext = uicontrol(gcf, 'Units', 'characters', 'Position', [106 8 18 2],...
        'String', 'Motion threshold  (mm / TR):', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
h_threshnummv = uicontrol(gcf, 'Units', 'characters', 'Position', [126 8 10 2],...
        'String', num2str(mv_thresh), 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8],...
        'Tag', 'threshnummv');
h_threshtextpct = uicontrol(gcf, 'Units', 'characters', 'Position', [66 8 16 2],...
        'String', 'Current threshold (% of mean):', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
h_threshnumpct = uicontrol(gcf, 'Units', 'characters', 'Position', [86 8 10 2],...
        'String', num2str(z_thresh*pctmap), 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8],...
        'Tag', 'threshnumpct');
h_deweightlist = uicontrol(gcf, 'Units', 'characters', 'Position', [150 6 1 1 ],...
        'String', int2str(outdw_idx), 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8],...
        'Tag', 'deweightlist');
h_clipmvmtlist = uicontrol(gcf, 'Units', 'characters', 'Position', [152 6 1 1 ],...
        'String', int2str(clipout_idx), 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8],...
        'Tag', 'clipmvmtlist');
h_indextext = uicontrol(gcf, 'Units', 'characters', 'Position', [10 3 15 2],...
        'String', 'Outlier indices: ', 'Style', 'text', ...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8], ...
        'ForegroundColor', 'r');
h_indexedit = uicontrol(gcf, 'Units', 'characters', 'Position', [25 3.25 40 2],...
        'String', int2str(out_idx), 'Style', 'edit', ...
        'HorizontalAlignment', 'left', ...
        'Callback', 'art_outlieredit',...
        'BackgroundColor', [0.8 0.8 0.8],...
        'Tag', 'indexedit');
h_indexinst = uicontrol(gcf, 'Units', 'characters', 'Position', [66 3 40 2],...
        'String', '[Hit return to update after editing]', 'Style', 'text',...
        'HorizontalAlignment', 'left', ...
        'BackgroundColor', [0.8 0.8 0.8]);
h_deweighttext = uicontrol(gcf, 'Units', 'characters', 'Position', [115 1 21 2],...
        'String', 'Click to add margins for deweighting', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
h_clipmvmttext = uicontrol(gcf, 'Units', 'characters', 'Position', [94 1 21 2],...
        'String', 'Mark > 3mm movments for repair', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
if realignfile == 1
   h_repairtext = uicontrol(gcf, 'Units', 'characters', 'Position', [137 1 17 2],...
        'String', 'Writes repaired volumes', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
else  % realignfile == 0
   h_repairtext = uicontrol(gcf, 'Units', 'characters', 'Position', [137 1 17 2],...
        'String', 'WARNING!! DATA NOT REALIGNED', 'Style', 'text', ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.8 0.8 0.8]);
end
h_addmargin = uicontrol(gcf, 'Units', 'characters', 'Position', [120 3.25 10 2],...
        'String', 'Margin', 'Style', 'pushbutton', ...
        'Tooltipstring', 'Adds margins to deweight in estimation', ...
        'BackgroundColor', [ 0.7 0.9 0.7], 'ForegroundColor','k',...
        'Callback', 'art_addmargin');
h_clipmvmt = uicontrol(gcf, 'Units', 'characters', 'Position', [100 3.25 10 2],...
        'String', 'Clip', 'Style', 'pushbutton', ...
        'Tooltipstring', 'Marks displacements > 3 mm for repair', ...
        'BackgroundColor', [ 0.7 0.7 0.8 ], 'ForegroundColor','k',...
        'Callback', 'art_clipmvmt');
h_repair = uicontrol(gcf, 'Units', 'characters', 'Position', [140 3.25 10 2],...
        'String', 'REPAIR', 'Style', 'pushbutton', ...
        'Tooltipstring', 'Writes repaired images', ...
        'BackgroundColor', [ 0.9 0.7 0.7], 'ForegroundColor','r',...
        'Callback', 'art_repairvol');
h_up = uicontrol(gcf, 'Units', 'characters', 'Position', [10 8 10 2],...
        'String', 'Up', 'Style', 'pushbutton', ...
        'TooltipString', 'Raise threshold for outliers', ...
        'Callback', 'art_threshup');
h_down = uicontrol(gcf, 'Units', 'characters', 'Position', [10 6 10 2],...
        'String', 'Down', 'Style', 'pushbutton', ...
        'TooltipString', 'Lower threshold for outliers', ...
        'Callback', 'art_threshdown');

guidata(gcf,[g delta mv_data]);
setappdata(h_repair,'data',P);
setappdata(h_addmargin,'data2',repair1_flag);
setappdata(h_clipmvmt,'data3',repair1_flag);

% 
if GoRepair == 0 | GoRepair == 1
    art_clipmvmt_jin(MVMTTHRESHOLD); %(movement to the referenced images)
    
    %!! This function adds the additional green lines around the red lines
    % marked for repair
    art_addmargin;
end

