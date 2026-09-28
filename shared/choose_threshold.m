function [threshold, achieved, n_predicted] = choose_threshold(scores, truth, targets, min_predicted, rule)
%CHOOSE_THRESHOLD Lowest score cut-off whose precision reaches each target.
%   [threshold, achieved, n_predicted] = choose_threshold(scores, truth, targets)
%   For each target precision, returns the cut-off t such that predicting
%   "yes" for scores >= t has precision >= target and makes as many "yes"
%   predictions as possible. If no cut-off reaches the target, threshold is
%   Inf (predict nobody) and achieved is NaN.
%
%   scores should be out-of-fold scores (from cross-validation on training
%   data). Resubstitution scores (used by get_score_thresholds) come from a
%   model that has already seen those patients, so the precision a cut-off
%   reaches on them says little about new patients.
%
%   rule: 'point' (default) compares the precision estimate with the target;
%   'lower_bound' compares its one-sided 95% Wilson lower bound, which guards
%   against cut-offs that reach the target by luck on a handful of cases.
%
%   Differences from the original selection rules:
%   * get_score_thresholds took the MIDDLE of the qualifying cut-offs
%     (round(mean(find(ppv >= target)))) instead of the one with most predictions;
%   * when nothing qualified, the original fell back to the highest score, i.e.
%     it still predicted someone, below the target precision.
if nargin < 4, min_predicted = 1; end
if nargin < 5, rule = 'point'; end
scores = scores(:);
truth = logical(truth(:));
[s, order] = sort(scores, 'descend');
t = truth(order);
tp = cumsum(t);
n = (1:numel(s))';
% a cut-off at score v includes every case scoring >= v, so only evaluate
% at the last position of each run of tied scores
ends = [s(1:end - 1) ~= s(2:end); true];
cut = s(ends); tp = tp(ends); n = n(ends);
prec = tp ./ n;
if strcmp(rule, 'lower_bound')
    z = 1.6449;                                  % one-sided 95%
    crit = (prec + z^2 ./ (2 * n) - z * sqrt(prec .* (1 - prec) ./ n + z^2 ./ (4 * n.^2))) ./ (1 + z^2 ./ n);
elseif strcmp(rule, 'point')
    crit = prec;
else
    error('choose_threshold:rule', 'rule must be ''point'' or ''lower_bound''.');
end

threshold = inf(size(targets));
achieved = nan(size(targets));
n_predicted = zeros(size(targets));
for k = 1:numel(targets)
    ok = crit >= targets(k) - 1e-12 & n >= min_predicted;
    j = find(ok, 1, 'last');            % n increases with j: most predictions
    if ~isempty(j)
        threshold(k) = cut(j);
        achieved(k) = prec(j);
        n_predicted(k) = n(j);
    end
end
end
