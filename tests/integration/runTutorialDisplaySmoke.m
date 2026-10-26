function summary = runTutorialDisplaySmoke(source, copies)
%RUNTUTORIALDISPLAYSMOKE Exact legacy comparison and paired preparation timings.
if nargin<2, copies=10; end
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); oldPath=path;
folder=tempname; mkdir(folder); cleanup=onCleanup(@() finish(oldPath,folder));
addpath(root,folder);
copyfile(fullfile(root,'tests','fixtures','viewerDisplayLegacyReference.m.txt'),fullfile(folder,'viewerDisplayLegacyReference.m'));
basename=ce.io.basenameFromBasepath(source); file=fullfile(source,[basename,'.cell_metrics.cellinfo.mat']);
hash=ce.pipeline.fileFingerprint(file); single=ce.io.readCellMetrics(file);
metrics=ce.data.assembleMetricBatch(repmat({single},1,copies), ...
    repmat({source},1,copies),repmat({basename},1,copies),'cell_metrics');
metrics.general.initialized=0;
intervals=-3:.04:1;
expected=viewerDisplayLegacyReference(metrics,intervals);
actual=ce.ui.prepareDisplayData(metrics,intervals);
assert(isequaln(actual,expected),'Display preparation differs from the frozen viewer formulas.');
clear expected actual;
legacySeconds=zeros(1,5); packageSeconds=zeros(1,5);
% Warmed alternating measurements avoid relying on cold GUI startup timings.
for iteration=1:5
    timer=tic; legacy=viewerDisplayLegacyReference(metrics,intervals); legacySeconds(iteration)=toc(timer);
    clear legacy;
    timer=tic; prepared=ce.ui.prepareDisplayData(metrics,intervals); packageSeconds(iteration)=toc(timer);
    clear prepared;
end
assert(strcmp(hash,ce.pipeline.fileFingerprint(file)));
summary=struct('cells',numel(metrics.UID),'legacySeconds',legacySeconds,'packageSeconds',packageSeconds, ...
    'legacyMedianSeconds',median(legacySeconds),'packageMedianSeconds',median(packageSeconds));
disp(summary);
end

function finish(originalPath,folder)
path(originalPath); if isfolder(folder), rmdir(folder,'s'); end
end
