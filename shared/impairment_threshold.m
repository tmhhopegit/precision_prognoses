function thr = impairment_threshold(P, task)
%IMPAIRMENT_THRESHOLD Threshold for a named score (scores >= threshold = unimpaired).
%   Structs from load_ploras store thresholds in BehaviourNames order.
%   Saved PLORAS_parallel objects stored them in the order of the thresholds
%   file (ImpairmentNames), while the analysis scripts indexed them by score
%   column - so a threshold only matched its score if both files used the
%   same order. Here the threshold is looked up by name in ImpairmentNames.
%   (If that file had a header row, check that names and values line up.)
if ~any(strcmp(P.BehaviourNames, task))
    error('impairment_threshold:task', 'Unknown score "%s".', task);
end
if has_field(P, 'ImpairmentNames') && ~isempty(P.ImpairmentNames)
    names = P.ImpairmentNames;
    if iscell(names) && size(names, 2) > 1, names = names(:, 1); end
    j = find(strcmp(cellstr(string(names)), task), 1);
    if isempty(j) || j > numel(P.ImpairmentThresholds)
        error('impairment_threshold:missing', 'No impairment threshold for "%s".', task);
    end
    thr = P.ImpairmentThresholds(j);
else
    thr = P.ImpairmentThresholds(strcmp(P.BehaviourNames, task));
end
if isempty(thr) || isnan(thr)
    error('impairment_threshold:missing', 'No impairment threshold for "%s".', task);
end
end
