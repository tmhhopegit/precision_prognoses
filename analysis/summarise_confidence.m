function S = summarise_confidence(res, mask)
%SUMMARISE_CONFIDENCE Precision and coverage for every target level.
%   S = summarise_confidence(res) or summarise_confidence(res, mask) where
%   mask selects a subgroup (e.g. early after stroke, initially impaired).
%   One row per target precision:
%     PPV            pooled over repeats: correct / predicted "unimpaired"
%     PPV_sd         SD of per-repeat PPV (repeats with no predictions skipped)
%     PPV_n          mean number predicted "unimpaired" per repeat
%     PPV_found      mean share of truly unimpaired patients predicted as such
%     NPV, NPV_sd, NPV_n, NPV_found   the same for "impaired"
%
%   Report every row, or a target fixed in advance. Picking the row with the
%   best PPV (as the original tables did with max(mean(ppvs,2))) chooses the
%   operating point on the test results and overstates precision.
if nargin < 2, mask = true(size(res.y)); end
mask = logical(mask(:));
y = res.y(mask);
T = numel(res.targets);
R = size(res.pred_pos, 2);
[ppv, ppv_sd, ppv_n, ppv_found, npv, npv_sd, npv_n, npv_found] = deal(nan(T, 1));
for t = 1:T
    pos = res.pred_pos(mask, :, t);
    neg = res.pred_neg(mask, :, t);
    [ppv(t), n_pos] = precision_count(pos, y);
    [npv(t), n_neg] = precision_count(neg, ~y);
    ppv_n(t) = n_pos / R;
    npv_n(t) = n_neg / R;
    ppv_found(t) = mean(sum(pos & y, 1)) / max(nnz(y), 1);
    npv_found(t) = mean(sum(neg & ~y, 1)) / max(nnz(~y), 1);
    ppv_sd(t) = std(per_repeat(pos, y), 'omitnan');
    npv_sd(t) = std(per_repeat(neg, ~y), 'omitnan');
end
n = repmat(numel(y), T, 1);
n_unimpaired = repmat(nnz(y), T, 1);
S = table(res.targets(:), ppv, ppv_sd, ppv_n, ppv_found, npv, npv_sd, npv_n, npv_found, n, n_unimpaired, ...
    'VariableNames', {'Target', 'PPV', 'PPV_sd', 'PPV_n', 'PPV_found', ...
                      'NPV', 'NPV_sd', 'NPV_n', 'NPV_found', 'N', 'N_unimpaired'});
end

function p = per_repeat(pred, truth)
p = nan(size(pred, 2), 1);
for r = 1:size(pred, 2)
    p(r) = precision_count(pred(:, r), truth);
end
end
