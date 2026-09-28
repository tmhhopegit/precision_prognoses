function folds = stratified_folds(y, K, R, seed)
%STRATIFIED_FOLDS Fold number for every case, for R repeats of K-fold CV.
%   folds = stratified_folds(y, K, R, seed) returns an n x R matrix.
%   Folds are balanced and stratified by the class labels y, so every fold
%   contains both classes (RUSBoost fails on single-class training data).
%   The original used randi(K, n, R): unbalanced, sometimes empty folds and
%   no stratification. If K >= n this is leave-one-out (one repeat).
y = y(:);
n = numel(y);
if K >= n
    folds = (1:n)';
    return
end
folds = zeros(n, R);
stream = RandStream('mt19937ar', 'Seed', seed);
for r = 1:R
    classes = unique(y);
    for c = 1:numel(classes)
        idx = find(y == classes(c));
        idx = idx(randperm(stream, numel(idx)));
        % deal cases round-robin, starting at a random fold
        start = randi(stream, K);
        folds(idx, r) = mod(start - 1 + (0:numel(idx) - 1)', K) + 1;
    end
end
end
