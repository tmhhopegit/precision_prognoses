function loads = lesion_loads(lesions, regions)
%LESION_LOADS Proportion of each region covered by each lesion.
%   loads = lesion_loads(lesions, regions)
%   lesions: patients x voxels (logical, or fuzzy values in [0,1])
%   regions: regions x voxels (logical)
%   loads:   patients x regions; empty regions give 0.
%
%   For binary lesions this is sum(lesion & region) / nnz(region), as in
%   EncodeLesionsByAnatomicalLoad; for fuzzy lesions it is the mean lesion
%   value inside the region.
regions = logical(regions);
sizes = sum(regions, 2)';
loads = (double(lesions) * double(regions')) ./ sizes;
loads(:, sizes == 0) = 0;
end
