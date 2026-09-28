function res = confidence_cv(X, y, cfg, learner)
%CONFIDENCE_CV High-confidence predictions, evaluated by nested cross-validation.
%   res = confidence_cv(X, y, cfg) with y true = unimpaired (recovered).
%
%   For every outer training fold:
%     1. out-of-fold scores on the training patients (inner CV);
%     2. for each target precision in cfg.targets, the lowest score cut-off
%        that reaches it with the most predictions - separately for
%        "unimpaired" (PPV) and "impaired" (NPV);
%     3. the test patients are scored by the same inner-fold models (their
%        scores averaged; cfg.final_model = 'inner_average', the default) or
%        by one model refitted on all training patients ('refit', as the
%        original), and predicted "unimpaired" / "impaired" if they pass.
%   Nothing about the test patients is used to choose models or cut-offs.
%   cfg.threshold_rule: 'point' (precision estimate >= target, default) or
%   'lower_bound' (one-sided 95% Wilson lower bound >= target; much more
%   conservative, far fewer predictions).
%
%   The precision this reports is what the method achieves on new patients;
%   it can fall short of the target (by up to 3 points in simulations with
%   150-300 patients), because the cut-off with most predictions sits where
%   training precision only just reaches the target.
%
%   res.pred_pos / res.pred_neg: n x R x T logical ("confidently unimpaired" /
%   "confidently impaired" for each repeat and target); res.scores: n x R x 2.
%   Summarise with summarise_confidence.
%
%   Replaces make_confidence_model + identify_thresholds_and_predict (and the
%   earlier test_confidence_model*, conf_inner). The latest version stored
%   the test-set PPVs and counts in Results{} and then read them back as if
%   they were thresholds and scores, so its predictions were meaningless.
if nargin < 4, learner = make_learner(cfg.learner); end
y = logical(y(:));
n = numel(y);
targets = cfg.targets(:)';
T = numel(targets);

folds = stratified_folds(y, cfg.outer_folds, cfg.outer_repeats, cfg.seed);
R = size(folds, 2);
K = max(folds(:));
jobs = [kron((1:R)', ones(K, 1)), repmat((1:K)', R, 1)];   % [repeat, fold]
nj = size(jobs, 1);

out = cell(nj, 1);
inner_K = cfg.inner_folds; inner_R = cfg.inner_repeats;
min_pred = cfg.min_predicted; seed = cfg.seed;
rule = 'point'; if isfield(cfg, 'threshold_rule'), rule = cfg.threshold_rule; end
refit = isfield(cfg, 'final_model') && strcmp(cfg.final_model, 'refit');
parfor (j = 1:nj, cfg.workers)
    te = folds(:, jobs(j, 1)) == jobs(j, 2);
    out{j} = one_fold(X(~te, :), y(~te), X(te, :), learner, targets, ...
        inner_K, inner_R, min_pred, seed + j, rule, refit);
end

res.y = y;
res.targets = targets;
res.folds = folds;
res.pred_pos = false(n, R, T);
res.pred_neg = false(n, R, T);
res.scores = nan(n, R, 2);
res.thr_pos = nan(nj, T);
res.thr_neg = nan(nj, T);
for j = 1:nj
    r = jobs(j, 1);
    te = folds(:, r) == jobs(j, 2);
    f = out{j};
    res.scores(te, r, :) = reshape(f.scores, [], 1, 2);
    res.pred_pos(te, r, :) = reshape(f.scores(:, 2) >= f.thr_pos, [], 1, T);
    res.pred_neg(te, r, :) = reshape(f.scores(:, 1) >= f.thr_neg, [], 1, T);
    res.thr_pos(j, :) = f.thr_pos;
    res.thr_neg(j, :) = f.thr_neg;
end
end

function f = one_fold(Xtr, ytr, Xte, learner, targets, K, R, min_pred, seed, rule, refit)
[oof, f.scores] = inner_scores(Xtr, ytr, learner, K, R, seed, Xte);
f.thr_neg = choose_threshold(oof(:, 1), ~ytr, targets, min_pred, rule);
f.thr_pos = choose_threshold(oof(:, 2), ytr, targets, min_pred, rule);
if refit
    mdl = learner.fit(Xtr, ytr);
    f.scores = learner.scores(mdl, Xte);
end
end
