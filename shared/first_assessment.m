function rows = first_assessment(P)
%FIRST_ASSESSMENT One row per patient: the lowest 'CAT Order' (first
%assessment), or the first row in the file if Order is missing.
%   The original used [~,b] = unique(P.IDs), which keeps the first row in
%   file order - not necessarily the first assessment.
ids = cellstr(string(P.IDs(:)));
order = nan(numel(ids), 1);
if has_field(P, 'Order') && numel(P.Order) == numel(ids)
    order = P.Order(:);
end
order(isnan(order)) = Inf;          % rows without an order come last
[~, ~, g] = unique(ids, 'stable');
rows = zeros(max(g), 1);
for k = 1:max(g)
    members = find(g == k);
    [~, best] = min(order(members));   % ties -> first in file
    rows(k) = members(best);
end
rows = sort(rows);
end
