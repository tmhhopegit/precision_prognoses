function [oof, new_scores] = inner_scores(X, y, learner, K, R, seed, Xnew)
%INNER_SCORES Out-of-fold classifier scores on training data.
%   [oof, new_scores] = inner_scores(X, y, learner, K, R, seed, Xnew)
%   oof:        n x 2 scores (impaired, unimpaired) from R repeats of
%               stratified K-fold CV on (X, y), averaged over repeats
%   new_scores: scores for Xnew, averaged over the same K x R fold models
%
%   Thresholds are chosen on oof and applied to new_scores. Both come from
%   the same kind of model (trained on (K-1)/K of the data), so they are on
%   the same scale. Applying oof-based thresholds to a model refitted on all
%   the training data - as identify_thresholds_and_predict did - mixes score
%   scales; in simulations it lowered held-out precision by up to 2 points.
%   get_score_thresholds used resubstitution scores instead.
y = logical(y(:));
if min(nnz(y), nnz(~y)) < 2
    error('inner_scores:classes', 'Each class needs at least 2 training cases (have %d and %d).', ...
        nnz(~y), nnz(y));
end
if nargin < 7, Xnew = zeros(0, size(X, 2)); end
folds = stratified_folds(y, K, R, seed);
oof = zeros(numel(y), 2);
new_scores = zeros(size(Xnew, 1), 2);
n_models = 0;
for r = 1:size(folds, 2)
    for k = unique(folds(:, r))'
        te = folds(:, r) == k;
        mdl = learner.fit(X(~te, :), y(~te));
        oof(te, :) = oof(te, :) + learner.scores(mdl, X(te, :));
        if ~isempty(Xnew)
            new_scores = new_scores + learner.scores(mdl, Xnew);
        end
        n_models = n_models + 1;
    end
end
oof = oof / size(folds, 2);
new_scores = new_scores / n_models;
end
