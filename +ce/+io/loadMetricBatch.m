function batch = loadMetricBatch(basepaths, basenames, saveAs, progress)
%LOADMETRICBATCH Local MAT loading with optional progress callback; no UI or DB.
if nargin < 2, basenames = {}; end
if nargin < 3, saveAs = 'cell_metrics'; end
if nargin < 4, progress = @(fraction,message) []; end
if ~iscellstr(basepaths) || isempty(basepaths) || ~isvector(basepaths) || ...
        ~iscellstr(basenames) || numel(basenames) > numel(basepaths)
    error('ce:io:InvalidBatchSources','Supply nonempty basepaths and at most one basename per path.');
end
basepaths = basepaths(:)'; basenames = basenames(:)'; timer = tic;
sessions = cell(size(basepaths));
for index = 1:numel(basepaths)
    if ~isfolder(basepaths{index}), error('ce:io:MissingMetrics','Directory not found: %s.',basepaths{index}); end
    [~,attributes] = fileattrib(basepaths{index}); basepaths{index} = attributes.Name;
    if numel(basenames) < index || isempty(basenames{index})
        basenames{index} = ce.io.basenameFromBasepath(basepaths{index});
    end
end
benchmark.clock(1) = toc(timer);
for index = 1:numel(basepaths)
    progress((index-1)/(numel(basepaths)+1),sprintf('%d/%d: %s',index,numel(basepaths),basenames{index}));
    fileTimer = tic;
    file = fullfile(basepaths{index},[basenames{index},'.',saveAs,'.cellinfo.mat']);
    sessions{index} = ce.io.readCellMetrics(file);
    benchmark.file_load(index) = toc(fileTimer);
    benchmark.file_cell_count(index) = sessions{index}.general.cellCount;
end
benchmark.clock(2) = toc(timer);
progress(numel(basepaths)/(numel(basepaths)+1),'Assembling cell metrics');
batch = ce.data.assembleMetricBatch(sessions,basepaths,basenames,saveAs);
benchmark.clock(3) = toc(timer); batch.general.batch_benchmark = benchmark;
progress(1,'Loading complete');
end
