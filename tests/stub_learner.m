function L = stub_learner()
%STUB_LEARNER A tiny base-MATLAB classifier for tests (no toolboxes needed).
%   Standardised mean-difference weights and a logistic link. It is only
%   meant to produce sensible, deterministic scores for the logic tests.
L.name = 'stub';
L.fit = @fit_stub;
L.scores = @score_stub;
end

function mdl = fit_stub(X, y)
y = logical(y(:));
mu = mean(X, 1);
sd = std(X, 0, 1);
sd(sd == 0) = 1;
mdl.mu = mu;
mdl.sd = sd;
mdl.w = (mean(X(y, :), 1) - mean(X(~y, :), 1)) ./ sd;
end

function s = score_stub(mdl, X)
z = ((X - mdl.mu) ./ mdl.sd) * mdl.w';
p = 1 ./ (1 + exp(-z));
s = [1 - p, p];
end
