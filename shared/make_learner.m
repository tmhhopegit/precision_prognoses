function L = make_learner(method, varargin)
%MAKE_LEARNER Classifier used by the confidence analyses.
%   L = make_learner('RUSBoost') returns a struct with
%     L.fit(X, y)       -> trained model (y logical)
%     L.scores(mdl, X)  -> n x 2 scores: column 1 for "impaired" (y = false),
%                          column 2 for "unimpaired" (y = true)
%   Extra arguments go to fitcensemble, e.g. make_learner('RUSBoost','Cost',C).
%   Passing a struct with fit/scores fields returns it unchanged, so tests and
%   other models can be plugged in.
if isstruct(method)
    L = method;
    return
end
opts = varargin;
L.name = method;
L.fit = @(X, y) fitcensemble(X, logical(y), 'Method', method, 'ClassNames', [false; true], opts{:});
L.scores = @score_fn;
end

function s = score_fn(mdl, X)
[~, s] = predict(mdl, X);
end
