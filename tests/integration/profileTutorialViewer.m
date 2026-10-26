function summary = profileTutorialViewer(source, copies, viewerFunction)
%PROFILETUTORIALVIEWER Profile opening and three cell advances without source writes.
% Repeated tutorial sessions are a scaling fixture, not independent recordings.
% PCA is selected explicitly; database, analytics and preference writes are off.
if nargin < 2, copies = 10; end
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
oldPath = path; oldDirectory = pwd;
existingFigures = findall(0,'Type','figure');
folder = tempname; mkdir(folder);
cleanup = onCleanup(@() cleanupEnvironment(oldDirectory,oldPath,folder,existingFigures));
addpath(genpath(root));
if nargin < 3, viewerFunction = @CellExplorer; end
basename = ce.io.basenameFromBasepath(source);
file = fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
hash = ce.pipeline.fileFingerprint(file);
readTimer = tic; single = ce.io.readCellMetrics(file); readSeconds = toc(readTimer);
assembleTimer = tic;
if copies == 1
    metrics = single;
else
    metrics = ce.data.assembleMetricBatch(repmat({single},1,copies), ...
        repmat({source},1,copies),repmat({basename},1,copies),'cell_metrics');
end
assembleSeconds = toc(assembleTimer);
writeStub('db_is_active','function value=db_is_active; value=false; end');
writeStub('trackGoogleAnalytics','function trackGoogleAnalytics(varargin); end');
writeStub('setLayout_CellExplorer',sprintf(['function value=setLayout_CellExplorer(value,mode)\n', ...
    'value.showIntroduction=false; value.tSNE.algorithm=''PCA''; end\n']));
addpath(folder); cd(folder); rehash;
completed = false; failure = []; cycles = 0; readySeconds = []; cycleTimes = []; initialTableCount = [];
started = tic; redrawTimer = tic;
watch = timer('ExecutionMode','fixedSpacing','Period',.25,'StartDelay',.25,'TimerFcn',@observe);
timerCleanup = onCleanup(@() stopTimer(watch));
profile clear; profile on; start(watch);
viewerFunction('metrics',metrics);
profile off; info = profile('info');
assert(completed,'Viewer did not reach the profiler completion point.');
if ~isempty(failure), rethrow(failure); end
assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
entries = info.FunctionTable;
names = {entries.FunctionName};
selected = contains(names,{'initializeSession','initializeUI','metricTableData','updateUI','interp1','normalize_range','prepareDisplay','prepareEmbedding','tsne','pca','findgroups','table'});
timings = struct('name',{},'calls',{},'totalSeconds',{},'selfSeconds',{});
for index = find(selected)
    item = entries(index); children = item.Children;
    childTime = 0; if ~isempty(children), childTime = sum([children.TotalTime]); end
    timings(end+1) = struct('name',item.FunctionName,'calls',item.NumCalls, ...
        'totalSeconds',item.TotalTime,'selfSeconds',max(0,item.TotalTime-childTime));
end
[~,order] = sort([timings.totalSeconds],'descend'); timings = timings(order);
summary = struct('cells',numel(metrics.UID),'copies',copies,'readSeconds',readSeconds, ...
    'assembleSeconds',assembleSeconds,'firstReadySeconds',readySeconds,'initialTableCount',initialTableCount, ...
    'navigationObservedSeconds',cycleTimes,'timings',timings);
disp(summary);
for index = 1:min(15,numel(timings))
    fprintf('%6.3f s  %6d calls  %s\n',timings(index).totalSeconds,timings(index).calls,timings(index).name);
end
stopTimer(watch);
cleanupEnvironment(oldDirectory,oldPath,folder,existingFigures);

    function observe(~,~)
        if completed, return; end
        figures=setdiff(findall(0,'Type','figure'),existingFigures);
        names=arrayfun(@(item) item.Name,figures,'UniformOutput',false);
        viewer=figures(startsWith(names,'CellExplorer v'));
        if isempty(viewer) || ~strcmp(viewer(1).WaitStatus,'waiting')
            if toc(started)>180
                failure=MException('test:ViewerTimeout','Viewer did not become ready.');
                completed=true; stop(watch); delete(figures);
            end
            return
        end
        if cycles==0
            readySeconds=toc(started); initialTableCount=numel(findall(viewer(1),'Type','uitable'));
        else, cycleTimes(end+1)=toc(redrawTimer); end
        cycles=cycles+1;
        if cycles<=3
            % Exercise actual navigation, including the selected-cell table.
            next=findall(viewer(1),'Type','uicontrol','Style','pushbutton','String',char(8594));
            assert(numel(next)==1,'Cannot locate the Next cell button.');
            redrawTimer=tic; next.Callback(next,[]);
        else
            completed=true; stop(watch); delete(viewer);
        end
    end
    function writeStub(name,body)
        fid=fopen(fullfile(folder,[name,'.m']),'w'); fprintf(fid,'%s\n',body); fclose(fid);
    end
end

function cleanupEnvironment(directory,originalPath,folder,existingFigures)
if ~isfolder(folder), return; end
profile off; cd(directory); path(originalPath);
delete(setdiff(findall(0,'Type','figure'),existingFigures));
if isfolder(folder), rmdir(folder,'s'); end
end

function stopTimer(watch)
if isvalid(watch), stop(watch); delete(watch); end
end
