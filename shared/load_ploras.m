function P = load_ploras(cfg)
%LOAD_PLORAS Read the PLORAS spreadsheet and lesion images into a struct.
%   P = load_ploras(cfg) replaces the PLORAS_parallel constructor. P has the
%   same field names as a PLORAS_parallel object (IDs, TimePost, Behaviours,
%   Predictors, LesionsBinary1D, ...), plus:
%     P.PredictorNames       names of the Predictors columns
%     P.ImpairmentThresholds matched to BehaviourNames BY NAME (NaN if absent)
%     P.ImageFailed          true where a lesion image could not be read
%
%   Fixes relative to PLORAS_parallel:
%   * thresholds were assigned by row order of the thresholds file, so they
%     only lined up with the scores if both files used the same order;
%   * the binary lesion-load branch referred to a non-existent property
%     (obj.LesionsBinary) and crashed; the "fuzzy" branch used binary lesions;
%   * unreadable images silently became empty lesions (volume 0); they are
%     now NaN and listed in P.ImageFailed;
%   * paths (Z:\Douglas\...) come from cfg.data instead of the code.
%
%   Needs SPM (spm_vol, spm_read_vols) on the path.

d = cfg.data;
raw = readcell(d.spreadsheet);
headers = cellfun(@to_text, raw(1, :), 'UniformOutput', false);
body = raw(2:end, :);
P.NumPatients = size(body, 1);

% ------------------------------------------------------------ scores
first = find_column(headers, d.first_behaviour);
last = find_column(headers, d.last_behaviour);
P.BehaviourNames = headers(first:last);
P.Behaviours = to_numeric(body(:, first:last));

% ------------------------------------------------------------ text fields
text_fields = {
    'ID',                  'IDs'
    'Handedness_Original', 'Hands'
    'Gender',              'Sex'
    'First Languages',     'L1'
    'Binary file',         'Fname_Binary'
    'Fuzzy file',          'Fname_Fuzzy'};
for i = 1:size(text_fields, 1)
    P.(text_fields{i, 2}) = cellfun(@to_text, body(:, find_column(headers, text_fields{i, 1})), ...
        'UniformOutput', false);
end

% ------------------------------------------------------------ numeric fields
numeric_fields = {
    'Days between CAT and scan',        'DaysScanCAT'
    'Months between stroke and scan',   'TimePost'
    'CAT Order',                        'Order'
    'Age At Stroke',                    'Age'
    'Years Education',                  'Education'
    'DifficultyWith_Speech',            'DiffSpeech'
    'DifficultyWith_Understanding',     'DiffUnderstanding'
    'DifficultyWith_Reading',           'DiffReading'
    'DifficultyWith_Writing',           'DiffWriting'
    'TPlusOneWeek_SpeechScore',         'Speech1wk'
    'TPlusOneWeek_UnderstandingScore',  'Understanding1wk'
    'TPlusOneWeek_ReadingScore',        'Reading1wk'
    'TPlusOneWeek_WritingScore',        'Writing1wk'
    'TPlusOneMonth_SpeechScore',        'Speech1mo'
    'TPlusOneMonth_UnderstandingScore', 'Understanding1mo'
    'TPlusOneMonth_ReadingScore',       'Reading1mo'
    'TPlusOneMonth_WritingScore',       'Writing1mo'
    'TPlusOneYear_SpeechScore',         'Speech1yr'
    'TPlusOneYear_UnderstandingScore',  'Understanding1yr'
    'TPlusOneYear_ReadingScore',        'Reading1yr'
    'TPlusOneYear_WritingScore',        'Writing1yr'};
for i = 1:size(numeric_fields, 1)
    P.(numeric_fields{i, 2}) = to_numeric(body(:, find_column(headers, numeric_fields{i, 1})));
end

% ------------------------------------------------------------ impairment thresholds (by name)
P.ImpairmentThresholds = nan(1, numel(P.BehaviourNames));
if ~isempty(d.thresholds_file)
    t = readcell(d.thresholds_file);
    matched = false(size(t, 1), 1);
    for r = 1:size(t, 1)
        name = to_text(t{r, 1});
        value = t{r, 2};
        k = find(strcmp(P.BehaviourNames, name), 1);
        if ~isempty(k) && isnumeric(value)
            P.ImpairmentThresholds(k) = value;
            matched(r) = true;
        end
    end
    if any(~matched(2:end))
        warning('load_ploras:thresholds', '%d threshold rows did not match a score name.', ...
            nnz(~matched(2:end)));
    end
end
P.ImpairmentLabels = P.Behaviours < P.ImpairmentThresholds;   % true = impaired

% ------------------------------------------------------------ lesion images
mask_img = spm_read_vols(spm_vol(d.brain_mask));
P.BrainVox = find(mask_img > 0);
[P.LesionsBinary1D, lesions_fuzzy, P.Vol, P.VolLeft, P.VolRight, P.ImageFailed] = ...
    read_lesions(P.Fname_Binary, P.Fname_Fuzzy, P.BrainVox, d.use_fuzzy, cfg.workers);
if any(P.ImageFailed)
    warning('load_ploras:images', '%d lesion images could not be read (see P.ImageFailed).', ...
        nnz(P.ImageFailed));
end

% ------------------------------------------------------------ lesion loads per region
[regions, P.AnatomicalRegionNames] = read_regions(d.region_folder, P.BrainVox);
if d.use_fuzzy
    source = lesions_fuzzy;
else
    source = single(P.LesionsBinary1D);
end
P.LesionLoads = lesion_loads(source, regions);
P.LesionLoads(P.ImageFailed, :) = NaN;

[dem, dem_names] = demographic_predictors(P);
[~, region_names] = cellfun(@fileparts, P.AnatomicalRegionNames, 'UniformOutput', false);
P.Predictors = [dem, double(P.LesionLoads)];
P.PredictorNames = [dem_names, region_names(:)'];
end

% ======================================================================
function [lb, lf, vol, voll, volr, failed] = read_lesions(fnb, fnf, bv, use_fuzzy, workers)
n = numel(fnb);
nv = numel(bv);
lb = false(n, nv);
lf = zeros(n, nv * use_fuzzy, 'single');
vol = nan(n, 1); voll = nan(n, 1); volr = nan(n, 1);
failed = false(n, 1);
parfor (p = 1:n, workers)
    try
        img = spm_read_vols(spm_vol(fnb{p}));
        les = img > 0;
        % Voxel x-index increasing = left hemisphere for the standard
        % 91x109x91 MNI grid (as the original: left = x 46:91).
        mid = ceil(size(les, 1) / 2);
        vol(p) = nnz(les);
        voll(p) = nnz(les(mid:end, :, :));
        volr(p) = nnz(les(1:mid - 1, :, :));
        lb(p, :) = les(bv)';
        if use_fuzzy
            f = spm_read_vols(spm_vol(fnf{p}));
            lf(p, :) = single(f(bv))';
        end
    catch
        failed(p) = true;
    end
end
end

function [regions, names] = read_regions(folder, bv)
files = [dir(fullfile(folder, '**', '*.img')); dir(fullfile(folder, '**', '*.nii'))];
names = sort(fullfile({files.folder}, {files.name}))';
if isempty(names)
    error('load_ploras:regions', 'No region images found in %s', folder);
end
regions = false(numel(names), numel(bv));
for f = 1:numel(names)
    img = spm_read_vols(spm_vol(names{f}));
    regions(f, :) = img(bv)' > 0;
end
end

function col = find_column(headers, name)
col = find(strcmp(headers, name), 1);
if isempty(col)
    error('load_ploras:column', 'Column "%s" not found in the spreadsheet.', name);
end
end

function s = to_text(v)
if ischar(v)
    s = v;
elseif isstring(v)
    s = char(v);
elseif isnumeric(v) && ~isempty(v) && ~isnan(v)
    s = num2str(v);
else
    s = '';
end
end

function x = to_numeric(c)
x = nan(size(c));
for k = 1:numel(c)
    v = c{k};
    if isnumeric(v) && isscalar(v)
        x(k) = v;
    elseif islogical(v) && isscalar(v)
        x(k) = double(v);
    elseif ischar(v) || isstring(v)
        x(k) = str2double(v);
    end
end
end
