%EXAMPLE_CONFIDENCE High-confidence prediction, section by section.
% Edit the paths below, then run each section (Ctrl+Enter).
run(fullfile(fileparts(mfilename('fullpath')), 'setup_confidence.m'));

cfg = config_confidence();
cfg.data.spreadsheet     = 'C:\path\to\PLORAS_export.xlsx';
cfg.data.thresholds_file = 'C:\path\to\ImpairmentThresholds.xlsx';
cfg.data.brain_mask      = 'C:\path\to\brain_mask.nii';
cfg.data.region_folder   = 'C:\path\to\regions';
cfg.workers = 4;                              % parfor workers (0 = serial)
cfg.tasks = {'NamingTScore'};
cfg.sample.initial_rating_field = {'NamingTScore', 'Speech1wk'};   % "initially impaired" subgroup

%% Load the data (needs SPM). A saved PLORAS_parallel object works too:
%   S = load('old.mat'); P = S.P;
P = load_ploras(cfg);

%% Run: nested cross-validation for every task, summaries saved to cfg.results_dir
results = run_confidence_analysis(P, cfg);
disp(results(1).summary.all)          % one row per target precision
disp(results(1).summary.early)        % patients seen early after stroke

%% Plot achieved vs target precision and how many patients are predicted
plot_confidence(results);
