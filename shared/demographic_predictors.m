function [X, names] = demographic_predictors(P)
%DEMOGRAPHIC_PREDICTORS The eight non-lesion predictors, as in
%ConvertDemographicsToPredictors:
%   TimePost, Age, NonRightHanded, Female, EnglishL1, Volume, VolumeLeft, VolumeRight
%
%   NonRightHanded = 'Left', 'Ambi' or containing 'ow Right' (e.g. "Left now Right").
%   Female = 'F' or 'Female'. EnglishL1 = first language contains "english"
%   (any case; the original matched 'NGLISH' or 'nglish').
n = numel(P.IDs);
hand = zeros(n, 1); sex = zeros(n, 1); lang = zeros(n, 1);
for i = 1:n
    h = text(P.Hands{i});
    hand(i) = strcmp(h, 'Left') || strcmp(h, 'Ambi') || contains(h, 'ow Right');
    s = text(P.Sex{i});
    sex(i) = strcmp(s, 'F') || strcmp(s, 'Female');
    lang(i) = contains(lower(text(P.L1{i})), 'english');
end
X = [P.TimePost(:), P.Age(:), hand, sex, lang, P.Vol(:), P.VolLeft(:), P.VolRight(:)];
names = {'TimePost', 'Age', 'NonRightHanded', 'Female', 'EnglishL1', 'Volume', 'VolumeLeft', 'VolumeRight'};
end

function s = text(v)
if ischar(v) || isstring(v)
    s = char(v);
else
    s = '';
end
end
