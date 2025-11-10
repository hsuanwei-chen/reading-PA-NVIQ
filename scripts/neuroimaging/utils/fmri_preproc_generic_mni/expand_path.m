function P = expand_path(in)
% P = expand_path(path_name)
%
% This function will expand a path name with wildcards into a list of
% complete path names.  For example, the command:
% P = expand_path('c:\my_experiment\subject_001\run_*\V*.img');
%
% will return
% P = 'c:\my_experiment\subject_001\run_01\V0001.img' ...
%     'c:\my_experiment\subject_001\run_01\V0002.img' ...
%       ...
%     'c:\my_experiment\subject_001\run_02\V0001.img' ...
%     'c:\my_experiment\subject_001\run_02\V0002.img' ...
%       ...
% and so on.
%
% The second feature is that if the CCN variable is declared, it
% can substitute in the values of fields CCN that are named in
% square brackets. So, the command:
% P = expand_path('c:\my_experiment\[subject]\[run_pattern]\[file_pattern]');
% will produce the same result as above if 
% CCN.subject = 'subject_0001', 
% CCN.run_pattern = 'run*', and
% CCN.file_pattern = 'V*.img'.
%
% The last feature is that you can define multiple values for a 
% substituted variable that will be used according to the calling function.
% Setting 
% CCN.file_pattern = struct('realign_b', 'aV*.img', ...
%   'default', 'V*.img');
% 
% will substitute in 'aV*.img' if realign_b is calling it, but
% 'V*.img' if any other function calls it.
%
% Ken Roberts
% October 8, 2003
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global CCN;

old_path = pwd;

% first find the square brackets that indicate replacement
l_brack = findstr(in, '[');
r_brack = findstr(in, ']');
st = dbstack;

% check the validity of the square bracket indices
if (size(l_brack) ~= size(r_brack)) ...              % same number of brackets
        | any(l_brack(2:end) < r_brack(1:end-1)) ... % brackets do not nest
        | any(l_brack > r_brack)                     % brackets in proper order
    error('Improperly formed expression, check the brackets');
end;

% if there are brackets, make sure CCN exists
if (l_brack ~= 0) & isempty(CCN)
    error('Variable CCN must be defined');
end;

% do the substitutions starting from the back
% (so replacing things does not alter the location of the other
% brackets)
for i = length(l_brack):-1:1
    key = in((l_brack(i)+1):(r_brack(i)-1));
    if isfield(CCN, key) 
        val = getfield(CCN, key);
        if isstruct(val)
            val = subst_name(val, st);
            in = cat(2, in(1:(l_brack(i)-1)), val, in((r_brack(i)+1):end) );
        elseif ischar(val)
            in = cat(2, in(1:(l_brack(i)-1)), val, in((r_brack(i)+1):end) );
        else
            error(sprintf('Improperly formed expression, CCN.%s must be a struct or char string.', key));
        end;
    else
        error(sprintf('Improperly formed expression, no variable CCN.%s', key));
    end;
end;

% expand a path recursively
P = exp_wc(in);
cd(old_path);
return;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Expand path helper function
% val = struct containing entries for each mfile that may call it.
% st = stack trace
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = subst_name(val, st)
fn = fieldnames(val);

% count down the struct fields
for i = length(st):-1:1
    for j = 1:length(fn)
        if findstr(st(i).name, fn{j})
            val = getfield(val, fn{j})
            return;
        end;
    end;
end;

% didnt find the field.
val = val.default;
return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Expand path helper function
% expands path recursively, and each argument in is always a single
% string (i.e., the expansion is on the way out)
%
% Only supported wildcard is '*'.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = exp_wc(in)

% find first wildcard
wc_index = min( [findstr(in, '?') findstr(in, '*')] );

% return, halting recursion if there are no wildcards
if isempty(wc_index)
    val = in;
    return;
end;    

% find base path, or path up to the filesep before the wild card
fs_indices = findstr(in, filesep);
bp_index = max( fs_indices(find(fs_indices < wc_index)) );
base_path = in(1:bp_index-1);

% return empty array if there are no completions
if ~exist(base_path)
    val = {};
    return;
end;
cd(base_path);

% looking for directories, or files?
if bp_index == max(fs_indices)
    % look for files, halts recursion
    val = {};
    fnames = dir(in(bp_index+1:end));
    for i = 1:length(fnames)
        if fnames(i).isdir == 0
            val = cat(2, val, cellstr([base_path filesep fnames(i).name]));
        end;
    end;
else
    % find remainder of path, or first filesep after wc
    rp_index = min( fs_indices(find(fs_indices > wc_index)) );
    rest_path = in(rp_index+1:end);
    
    % look for directories and recurse
    val = {};
    fnames = dir(in(bp_index+1:rp_index-1));
    for i = 1:length(fnames)
        if (fnames(i).isdir == 1) & (isempty(findstr(fnames(i).name, '.')))
            p = [base_path filesep fnames(i).name filesep rest_path];
            val = cat(2, val, cellstr(exp_wc(p)) );
        end;
    end;
end;

return;
