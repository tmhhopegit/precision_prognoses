function cfg = config_confidence()
%CONFIG_CONFIDENCE Settings for the high-confidence prediction analysis.
%   cfg = config_confidence();  then change fields as needed, e.g.
%   cfg.data.spreadsheet = 'C:\data\PLORAS.xlsx';
%   Everything the original scripts hard-coded (paths, column numbers,
%   cut-offs, numbers of folds and repeats) is set here.

% ---------------------------------------------------------------- data (load_ploras)
cfg.data.spreadsheet      = '';        % PLORAS export (.xlsx)
cfg.data.thresholds_file  = '';        % ImpairmentThresholds.xlsx: score name + threshold
cfg.data.brain_mask       = '';        % brain mask image (replaces GetMasks)
cfg.data.region_folder    = '';        % folder of binary region images (.img/.nii), searched recursively
cfg.data.use_fuzzy        = false;     % lesion loads from fuzzy instead of binary lesion images
cfg.data.first_behaviour  = 'LineBisTScore';   % scores are the columns from here ...
cfg.data.last_behaviour   = 'MemTot';          % ... to here

% ---------------------------------------------------------------- patients
cfg.sample.first_assessment_only = true;  % one row per patient (lowest 'CAT Order', else first row)
cfg.sample.english_only          = false; % only patients with English as a first language
cfg.sample.drop_predictors       = {};    % predictor names to leave out, e.g. {'EnglishL1','Volume'}

% ---------------------------------------------------------------- subgroups
cfg.sample.early_months          = 6;     % 'early' subgroup: time post-stroke <= this (was 6, 6.5 or 7)
% Subjective rating that defines "initially impaired" for each task:
% rows = {task name, rating field}. Ratings in impaired_rating_range count as impaired.
cfg.sample.initial_rating_field  = {};    % e.g. {'NamingTScore','Speech1mo'; 'ReadingTScore','Reading1mo'}
cfg.sample.impaired_rating_range = [2 6];

% ---------------------------------------------------------------- analysis
cfg.tasks            = {};                 % score names to analyse (empty = all with a threshold)
cfg.targets          = 0.80:0.01:1.00;     % desired precision levels
cfg.outer_folds      = 10;                 % K
cfg.outer_repeats    = 10;                 % R
cfg.inner_folds      = 10;
cfg.inner_repeats    = 1;
cfg.min_predicted    = 1;                  % a threshold must make at least this many inner predictions
cfg.threshold_rule   = 'point';            % 'point' or 'lower_bound' (conservative)
cfg.final_model      = 'inner_average';    % score test patients with the inner models ('refit' = original)
cfg.learner          = 'RUSBoost';         % fitcensemble method ('RUSBoost', 'AdaBoostM1', ...)

% ---------------------------------------------------------------- general
cfg.seed        = 1;
cfg.workers     = 0;       % parfor workers (0 = run serially)
cfg.verbose     = true;
cfg.results_dir = fullfile(pwd, 'results');
end
