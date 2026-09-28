function names = predictor_names(P)
%PREDICTOR_NAMES Names of the columns of P.Predictors.
%   Works for structs from load_ploras (P.PredictorNames) and for saved
%   PLORAS_parallel objects, whose Predictors are the 8 demographic
%   predictors followed by one lesion load per region.
if has_field(P, 'PredictorNames') && ~isempty(P.PredictorNames)
    names = P.PredictorNames;
    return
end
dem = {'TimePost', 'Age', 'NonRightHanded', 'Female', 'EnglishL1', 'Volume', 'VolumeLeft', 'VolumeRight'};
n_regions = size(P.Predictors, 2) - numel(dem);
if has_field(P, 'AnatomicalRegionNames') && numel(P.AnatomicalRegionNames) == n_regions
    [~, regions] = cellfun(@fileparts, P.AnatomicalRegionNames, 'UniformOutput', false);
    regions = regions(:)';
else
    regions = arrayfun(@(k) sprintf('Region%03d', k), 1:n_regions, 'UniformOutput', false);
end
names = [dem, regions];
end
