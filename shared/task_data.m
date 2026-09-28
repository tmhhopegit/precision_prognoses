function D = task_data(P, task, cfg)
%TASK_DATA Predictors and outcome for one score.
%   D = task_data(P, task, cfg) returns a struct with
%     X, names     predictors (after cfg.sample.drop_predictors)
%     score        the raw score
%     y            true = unimpaired (score >= impairment threshold)
%     threshold    the impairment threshold used
%     rows         rows of P used (one per patient if first_assessment_only)
%     ids, time_post
%   Rows with any missing predictor or score are dropped, as before.
names = predictor_names(P);
X = P.Predictors;
score = P.Behaviours(:, strcmp(P.BehaviourNames, task));
if isempty(score)
    error('task_data:task', 'Unknown score "%s".', task);
end

rows = (1:size(X, 1))';
if cfg.sample.first_assessment_only
    rows = first_assessment(P);
end
keep = ~any(isnan([X(rows, :), score(rows)]), 2);
if cfg.sample.english_only
    keep = keep & X(rows, strcmp(names, 'EnglishL1')) > 0;
end
rows = rows(keep);

drop = ismember(names, cfg.sample.drop_predictors);
D.X = X(rows, ~drop);
D.names = names(~drop);
D.score = score(rows);
D.threshold = impairment_threshold(P, task);
D.y = D.score >= D.threshold;
D.rows = rows;
D.ids = cellstr(string(P.IDs(rows)));
D.time_post = P.TimePost(rows);
D.task = task;
end
