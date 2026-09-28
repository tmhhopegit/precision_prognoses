%SETUP_CONFIDENCE Put the high-confidence prediction analysis code on the MATLAB path.
%   Run once per session:  run('<this folder>/setup_confidence.m')
%   Each project folder is self-contained; its own copies of the shared
%   helpers are put first on the path, so they are the ones used even if
%   another project's folder is on the path too.
root = fileparts(mfilename('fullpath'));
for sub = {'tests', 'shared', 'analysis'}
    addpath(fullfile(root, sub{1}));
end
addpath(root);
clear root sub
