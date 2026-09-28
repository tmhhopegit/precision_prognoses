function r = model_sensitivity(mdl, X, reps, learner, seed)
%MODEL_SENSITIVITY Which predictors move the model's "unimpaired" score.
%   r = model_sensitivity(mdl, X, reps, learner) repeatedly shuffles a random
%   subset of predictor columns across patients, scores the perturbed data,
%   and returns the correlation between each predictor and the score over all
%   perturbed copies (one value per predictor). Replaces
%   interpret_model_patches, now reproducible (seed) and learner-agnostic.
if nargin < 4, learner = make_learner('RUSBoost'); end
if nargin < 5, seed = 1; end
stream = RandStream('mt19937ar', 'Seed', seed);
[nr, nc] = size(X);
Xs = zeros(nr * reps, nc);
s = zeros(nr * reps, 1);
for i = 1:reps
    cols = randperm(stream, nc, randi(stream, nc));
    tmp = X;
    tmp(:, cols) = X(randperm(stream, nr), cols);
    sc = learner.scores(mdl, tmp);
    rows = (i - 1) * nr + (1:nr);
    Xs(rows, :) = tmp;
    s(rows) = sc(:, 2);
end
r = corr(Xs, s);
end
