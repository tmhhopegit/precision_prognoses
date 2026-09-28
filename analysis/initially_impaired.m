function mask = initially_impaired(P, D, cfg)
%INITIALLY_IMPAIRED Patients who rated themselves impaired early on, in the
%domain that matches the task (e.g. Speech1mo for a naming score).
%   mask = initially_impaired(P, D, cfg) uses cfg.sample.initial_rating_field
%   (rows {task, rating field}) and cfg.sample.impaired_rating_range ([2 6]:
%   the original's subj > 1 & subj <= 6). Returns [] if the task has no
%   rating field configured.
%
%   Replaces the index-based mappings in get_ppv, test_confidence_model_v3b
%   and make_subset_tbl (which used different column orders and a mix of
%   1-week and 1-month ratings), and get_ys's hard-coded 1:3861 truncation.
map = cfg.sample.initial_rating_field;
mask = [];
if isempty(map), return; end
k = find(strcmp(map(:, 1), D.task), 1);
if isempty(k), return; end
ratings = P.(map{k, 2});
ratings = ratings(D.rows);
lim = cfg.sample.impaired_rating_range;
mask = ratings >= lim(1) & ratings <= lim(2);
end
