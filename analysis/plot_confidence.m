function fig = plot_confidence(results, group)
%PLOT_CONFIDENCE Achieved vs target precision, and how many are predicted.
%   fig = plot_confidence(results) or plot_confidence(results, 'early')
%   One line per task; the dashed line is achieved = target.
%   Replaces make_ppv_figs and av_ppp.
if nargin < 2, group = 'all'; end
fig = figure('Color', 'w');
titles = {'Confidently unimpaired (PPV)', 'Confidently impaired (NPV)'};
cols = {'PPV', 'NPV'};
for c = 1:2
    subplot(2, 2, c); hold on
    for i = 1:numel(results)
        S = results(i).summary.(group);
        plot(S.Target, S.(cols{c}), 'LineWidth', 1.2, 'DisplayName', results(i).task);
    end
    lims = [min(S.Target), 1];
    plot(lims, lims, 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    xlabel('Target precision'); ylabel('Achieved precision'); title(titles{c}); grid on
    subplot(2, 2, c + 2); hold on
    for i = 1:numel(results)
        S = results(i).summary.(group);
        plot(S.Target, S.([cols{c} '_found']), 'LineWidth', 1.2, 'DisplayName', results(i).task);
    end
    xlabel('Target precision'); ylabel('Share of class identified'); grid on
end
legend('Location', 'bestoutside', 'Interpreter', 'none');
end
