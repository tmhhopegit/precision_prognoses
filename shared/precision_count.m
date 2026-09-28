function [precision, n_predicted, n_correct] = precision_count(predicted, truth)
%PRECISION_COUNT Precision of a set of "yes" predictions.
%   predicted, truth: logical vectors (or n x R matrices, one column per
%   repeat, pooled). precision is NaN when nothing is predicted - it is never
%   silently turned into 0 (get_npv) or dropped from an average (get_ppv).
%   Use ~truth as the truth to get negative predictive value.
%   Replaces get_ppv, get_npv and calc_ppv_and_npv.
predicted = logical(predicted);
if isvector(predicted), predicted = predicted(:); end
truth = logical(truth(:));
truth = repmat(truth, 1, size(predicted, 2));
n_predicted = nnz(predicted);
n_correct = nnz(predicted & truth);
precision = n_correct / n_predicted;
if n_predicted == 0
    precision = NaN;
end
end
