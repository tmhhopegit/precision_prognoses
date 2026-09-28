classdef ConfidenceTest < matlab.unittest.TestCase
%CONFIDENCETEST Checks the high-confidence prediction code (uses stub_learner, so no toolboxes needed).
%   From this project's folder:  setup_confidence; results = runtests('tests')
%   Tests that need the Statistics and Machine Learning Toolbox are skipped
%   when it is not installed.

    methods (TestClassSetup)
        function addPaths(tc) %#ok<MANU>
            here = fileparts(mfilename('fullpath'));
            run(fullfile(here, '..', 'setup_confidence.m'));
        end
    end

    methods (Test)
        function testThresholdMostPredictions(tc)
            % scores descending: 9 8 7 6 5 4 ; truth 1 1 0 1 1 0
            s = [9 8 7 6 5 4]';
            y = logical([1 1 0 1 1 0]');
            % precision by cut-off: 1, 1, .667, .75, .8, .667
            [thr, got, n] = choose_threshold(s, y, [0.8 1.0]);
            tc.verifyEqual(thr, [5 8]);          % lowest cut-off reaching each target
            tc.verifyEqual(got, [0.8 1.0], 'AbsTol', 1e-12);
            tc.verifyEqual(n, [5 2]);
        end

        function testThresholdTiesEvaluatedTogether(tc)
            % a tie at 5 contains one positive and one negative: the cut-off
            % at 5 includes both, so precision there is 3/4, not 3/3
            s = [9 8 5 5]';
            y = logical([1 1 1 0]');
            thr = choose_threshold(s, y, 0.9);
            tc.verifyEqual(thr, 8);
        end

        function testThresholdAbstains(tc)
            s = (1:10)';
            y = false(10, 1);
            [thr, got, n] = choose_threshold(s, y, 0.8);
            tc.verifyEqual(thr, Inf);
            tc.verifyTrue(isnan(got));
            tc.verifyEqual(n, 0);
        end

        function testThresholdMinPredicted(tc)
            s = [9 8 7]';
            y = logical([1 0 0]');
            tc.verifyEqual(choose_threshold(s, y, 1.0, 1), 9);
            tc.verifyEqual(choose_threshold(s, y, 1.0, 2), Inf);
        end

        function testLowerBoundIsConservative(tc)
            s = (20:-1:1)';
            y = [true(10, 1); false(10, 1)];
            [~, ~, n_point] = choose_threshold(s, y, 0.9, 1, 'point');
            [~, ~, n_lb] = choose_threshold(s, y, 0.9, 1, 'lower_bound');
            tc.verifyEqual(n_point, 11);         % 10/11 = .909
            tc.verifyLessThan(n_lb, n_point);
        end

        function testFoldsBalancedAndStratified(tc)
            y = [true(30, 1); false(13, 1)];
            f = stratified_folds(y, 5, 3, 7);
            tc.verifySize(f, [43 3]);
            for r = 1:3
                counts = accumarray(f(:, r), 1, [5 1]);
                tc.verifyLessThanOrEqual(max(counts) - min(counts), 2);
                pos = accumarray(f(y, r), 1, [5 1]);
                tc.verifyLessThanOrEqual(max(pos) - min(pos), 1);
                neg = accumarray(f(~y, r), 1, [5 1]);
                tc.verifyLessThanOrEqual(max(neg) - min(neg), 1);
            end
            tc.verifyEqual(stratified_folds(y, 5, 3, 7), f);   % reproducible
        end

        function testFoldsLeaveOneOut(tc)
            f = stratified_folds(logical([1 0 1 0]'), 10, 5, 1);
            tc.verifyEqual(f, (1:4)');
        end

        function testPrecisionCount(tc)
            pred = logical([1 1 0; 1 0 0; 0 0 0]);
            truth = logical([1 0 1]');
            [p, n, c] = precision_count(pred, truth);
            tc.verifyEqual([p n c], [2/3 3 2], 'AbsTol', 1e-12);
            tc.verifyTrue(isnan(precision_count(false(3, 1), truth)));
        end

        function testFirstAssessment(tc)
            P.IDs = {'a'; 'b'; 'a'; 'c'; 'b'};
            P.Order = [2; 1; 1; NaN; 1];
            rows = first_assessment(P);
            tc.verifyEqual(rows, [2; 3; 4]);    % b: tie -> first row; a: order 1
        end

        function testConfidenceCvSmoke(tc)
            [X, y] = ConfidenceTest.synthetic(120, 3);
            cfg = ConfidenceTest.smallConfig();
            res = confidence_cv(X, y, cfg, stub_learner());
            T = numel(cfg.targets);
            tc.verifySize(res.pred_pos, [120 2 T]);
            tc.verifyFalse(any(isnan(res.scores(:))));
            S = summarise_confidence(res);
            tc.verifyEqual(height(S), T);
            % a strong planted effect should give some confident predictions
            % with precision well above the base rate
            tc.verifyGreaterThan(S.PPV_n(1), 0);
            tc.verifyGreaterThan(S.PPV(1), mean(y) + 0.1);
            % subgroup masks work
            S2 = summarise_confidence(res, (1:120)' <= 60);
            tc.verifyEqual(S2.N(1), 60);
        end

        function testConfidenceCvRefitOption(tc)
            [X, y] = ConfidenceTest.synthetic(80, 4);
            cfg = ConfidenceTest.smallConfig();
            cfg.final_model = 'refit';
            res = confidence_cv(X, y, cfg, stub_learner());
            tc.verifySize(res.scores, [80 2 2]);
        end

        function testRusboostSmoke(tc)
            tc.assumeTrue(exist('fitcensemble', 'file') == 2, ...
                'Statistics and Machine Learning Toolbox not available');
            [X, y] = ConfidenceTest.synthetic(80, 5);
            cfg = ConfidenceTest.smallConfig();
            res = confidence_cv(X, y, cfg);
            tc.verifySize(res.pred_pos, [80 2 numel(cfg.targets)]);
        end

    end

    methods (Static)
        function cfg = smallConfig()
            cfg = config_confidence();
            cfg.targets = [0.8 0.9];
            cfg.outer_folds = 5;
            cfg.outer_repeats = 2;
            cfg.inner_folds = 4;
            cfg.inner_repeats = 1;
            cfg.workers = 0;
            cfg.verbose = false;
        end

        function [X, y, score] = synthetic(n, seed)
            s = RandStream('mt19937ar', 'Seed', seed);
            X = randn(s, n, 4);
            score = 2 * X(:, 2) - X(:, 3) + 0.5 * randn(s, n, 1);
            y = score > 0;
        end
    end
end
