% Run the component regression suite without personal data or startup settings.
results = runComponentTests;

function results = runComponentTests
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
cleanup = onCleanup(@() path(originalPath));
addpath(root, fullfile(root,'calc_CellMetrics'));
results = runtests(fullfile(root,'tests'), 'IncludeSubfolders', true);
assertSuccess(results);
fprintf('\n%d tests passed.\n', numel(results));
end
