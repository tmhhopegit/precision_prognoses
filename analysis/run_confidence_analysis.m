function results = run_confidence_analysis(P, cfg)
%RUN_CONFIDENCE_ANALYSIS High-confidence recovery predictions for each task.
%   results = run_confidence_analysis(P, cfg)
%   P:   data from load_ploras (or a saved PLORAS_parallel object)
%   cfg: config_confidence() with cfg.tasks etc. set
%
%   For each task: build the data (task_data), run nested CV (confidence_cv),
%   and summarise for all patients, the early subgroup (time post-stroke <=
%   cfg.sample.early_months) and, if configured, the initially impaired.
%   Saves confidence_<task>.mat and confidence_summary.csv in cfg.results_dir.
tasks = cfg.tasks;
if isempty(tasks)
    tasks = P.BehaviourNames(cellfun(@(t) has_threshold(P, t), P.BehaviourNames));
end
if ~exist(cfg.results_dir, 'dir'), mkdir(cfg.results_dir); end
learner = make_learner(cfg.learner);

results = struct('task', {}, 'data', {}, 'cv', {}, 'summary', {});
all_rows = {};
for i = 1:numel(tasks)
    task = tasks{i};
    if cfg.verbose, fprintf('%s (%d/%d)\n', task, i, numel(tasks)); end
    D = task_data(P, task, cfg);
    res = confidence_cv(D.X, D.y, cfg, learner);

    groups = {'all', true(size(D.y)); 'early', D.time_post <= cfg.sample.early_months};
    init = initially_impaired(P, D, cfg);
    if ~isempty(init), groups(end + 1, :) = {'initially_impaired', init}; end
    summary = struct();
    for g = 1:size(groups, 1)
        S = summarise_confidence(res, groups{g, 2});
        summary.(groups{g, 1}) = S;
        S.Task = repmat({task}, height(S), 1);
        S.Group = repmat(groups(g, 1), height(S), 1);
        all_rows{end + 1} = S; %#ok<AGROW>
    end

    results(i).task = task;
    results(i).data = rmfield(D, 'X');
    results(i).cv = res;
    results(i).summary = summary;
    save(fullfile(cfg.results_dir, ['confidence_' matlab.lang.makeValidName(task) '.mat']), ...
        'res', 'D', 'summary', 'cfg');
end
if ~isempty(all_rows)
    summary_table = vertcat(all_rows{:});
    summary_table = movevars(summary_table, {'Task', 'Group'}, 'Before', 1);
    writetable(summary_table, fullfile(cfg.results_dir, 'confidence_summary.csv'));
end
end

function tf = has_threshold(P, task)
try
    impairment_threshold(P, task);
    tf = true;
catch
    tf = false;
end
end
