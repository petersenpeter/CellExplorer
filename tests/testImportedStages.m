function tests = testImportedStages
tests = functiontests(localfunctions);
end

function setup(testCase)
folder = tempname; mkdir(folder);
testCase.TestData.folder = folder;
testCase.TestData.originalPath = path;
root = fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'util'));
testCase.TestData.session.general = struct('name','synthetic','basePath',folder);
testCase.TestData.spikes = struct('UID',[7 9],'cluID',[21 42]);
testCase.TestData.parameters = ce.pipeline.parseParameters('headless',true, ...
    'metrics',{'spatial_metrics','psth_metrics'});
end

function teardown(testCase)
path(testCase.TestData.originalPath);
rmdir(testCase.TestData.folder,'s');
end

function testNamedLoadAlignmentAndSourceProtection(testCase)
ratemap = mapFixture; ratemap.UID = [9 7]; ratemap.cluID = [42 21];
parameters = 'Do not load into caller'; %#ok<NASGU>
file = fullfile(testCase.TestData.folder,'synthetic.ratemap.firingRateMap.mat');
save(file,'ratemap','parameters'); hash = ce.pipeline.fileFingerprint(file);
records = read(testCase,'spatial_metrics');
verifyEqual(testCase,records.data.map,ratemap.map([2 1]));
verifyEqual(testCase,records.data.x_bins,ratemap.x_bins);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),hash);
parameters = 'A metadata-only edit still invalidates the file'; %#ok<NASGU>
save(file,'ratemap','parameters'); changed = read(testCase,'spatial_metrics');
verifyNotEqual(testCase,changed.sha256,records.sha256);
verifyEqual(testCase,changed.data,records.data);
end

function testIdentityRequiredEvenForMatchingCounts(testCase)
ratemap = rmfield(mapFixture,'UID'); write(testCase,'ratemap','firingRateMap',ratemap);
verifyError(testCase,@() read(testCase,'spatial_metrics'),'ce:pipeline:CellImportIdentity');
for ids = {[7 7],[7 11],[7 NaN],7}
    ratemap.UID = ids{1}; write(testCase,'ratemap','firingRateMap',ratemap);
    verifyError(testCase,@() read(testCase,'spatial_metrics'),'ce:pipeline:CellImportIdentity');
end
end

function testClusterIdentityAndConflictingMappings(testCase)
ratemap = rmfield(mapFixture,'UID'); ratemap.cluID = [42 21];
write(testCase,'ratemap','firingRateMap',ratemap);
records = read(testCase,'spatial_metrics');
verifyEqual(testCase,records.data.map,ratemap.map([2 1]));
ratemap.UID = [7 9]; write(testCase,'ratemap','firingRateMap',ratemap);
verifyError(testCase,@() read(testCase,'spatial_metrics'),'ce:pipeline:CellImportIdentity');
end

function testEveryCellDimensionsChecked(testCase)
ratemap = mapFixture; ratemap.map{2} = [1;2];
write(testCase,'ratemap','firingRateMap',ratemap);
verifyError(testCase,@() read(testCase,'spatial_metrics'),'ce:pipeline:InvalidCellImport');
ratemap = mapFixture; ratemap.map{2}(:,2) = ratemap.map{2};
write(testCase,'ratemap','firingRateMap',ratemap);
verifyError(testCase,@() read(testCase,'spatial_metrics'),'ce:pipeline:InvalidCellImport');
delete(fullfile(testCase.TestData.folder,'synthetic.ratemap.firingRateMap.mat'));
write(testCase,'trials','firingRateMap',ratemap);
records = read(testCase,'spatial_metrics');
verifyEqual(testCase,records.data.map,ratemap.map);
end

function testReservedMapAliasCollision(testCase)
write(testCase,'ratemap','firingRateMap',mapFixture);
write(testCase,'firingRateMap','firingRateMap',mapFixture);
verifyError(testCase,@() read(testCase,'spatial_metrics'),'ce:pipeline:AmbiguousCellImport');
end

function testPsthViewerLayoutAndLabels(testCase)
flash = psthFixture; write(testCase,'flash','psth',flash);
[metrics,results] = run(testCase,struct());
verifyEqual(testCase,{results.status},{'completed','completed'});
verifyEqual(testCase,metrics.psth.flash,{flash.unit(:,2),flash.unit(:,1)});
verifyEqual(testCase,metrics.general.psth.flash.x_label,'Time (s)');
verifyEqual(testCase,metrics.general.psth.flash.boundaries,0);
verifyFalse(testCase,isfield(metrics,'synthetic.flash.psth'));
metrics.general.cellCount = 2;
ce.data.validateCellMetricsStruct(metrics);
flash.unit = flash.unit(1:2,:); write(testCase,'flash','psth',flash);
verifyError(testCase,@() read(testCase,'psth_metrics'),'ce:pipeline:InvalidCellImport');
end

function testCacheIndependenceAndDeletedOutputs(testCase)
write(testCase,'ratemap','firingRateMap',mapFixture);
write(testCase,'flash','psth',psthFixture);
initial.psth.custom = {8,9}; initial.labels = {'a','b'};
[first,~] = run(testCase,initial);
[again,results] = run(testCase,first);
verifyEqual(testCase,{results.status},{'reused','reused'}); verifyEqual(testCase,again,first);
flash = psthFixture; flash.unit(1) = 17; write(testCase,'flash','psth',flash);
[changed,results] = run(testCase,again);
verifyEqual(testCase,{results.status},{'reused','completed'});
delete(fullfile(testCase.TestData.folder,'synthetic.flash.psth.mat'));
delete(fullfile(testCase.TestData.folder,'synthetic.ratemap.firingRateMap.mat'));
[removed,results] = run(testCase,changed);
verifyEqual(testCase,{results.status},{'completed','completed'});
verifyFalse(testCase,isfield(removed.psth,'flash'));
verifyFalse(testCase,isfield(removed.general.psth,'flash'));
verifyFalse(testCase,isfield(removed,'spatialPeakRate'));
verifyEmpty(testCase,fieldnames(removed.firingRateMaps));
verifyEqual(testCase,removed.psth.custom,initial.psth.custom);
verifyEqual(testCase,removed.labels,initial.labels);
[~,results] = run(testCase,removed);
verifyEqual(testCase,{results.status},{'reused','reused'});
end

function testSkippingDoesNotReadBrokenInputOrRetireOutputs(testCase)
write(testCase,'flash','psth',psthFixture);
[first,~] = run(testCase,struct());
write(testCase,'flash','psth',struct());
testCase.TestData.parameters.excludeMetrics = {'psth_metrics'};
[again,results] = run(testCase,first);
verifyEqual(testCase,results(2).status,'skipped'); verifyEqual(testCase,again,first);
end

function testIntervalsDoNotRelabelPrecomputedImports(testCase)
write(testCase,'flash','psth',psthFixture);
[first,~] = run(testCase,struct());
testCase.TestData.parameters.restrictToIntervals = [10 20];
testCase.TestData.parameters.excludeIntervals = [12 13];
[again,results] = run(testCase,first);
verifyEqual(testCase,{results.status},{'reused','reused'}); verifyEqual(testCase,again,first);
end

function testEditedOutputRepairedAndRenamedInputRetired(testCase)
write(testCase,'flash','psth',psthFixture);
[first,~] = run(testCase,struct());
first.general.psth.flash.x_label = 'Incorrect';
[repaired,results] = run(testCase,first);
verifyEqual(testCase,results(2).reason,'changed_outputs');
verifyEqual(testCase,repaired.general.psth.flash.x_label,'Time (s)');
delete(fullfile(testCase.TestData.folder,'synthetic.flash.psth.mat'));
write(testCase,'pulse','psth',psthFixture);
[renamed,~] = run(testCase,repaired);
verifyFalse(testCase,isfield(renamed.psth,'flash'));
verifyTrue(testCase,isfield(renamed.psth,'pulse'));
end

function testBatchPreservesPsthColumnsAndPadsMissingSessions(testCase)
% Isolate the legacy batch loader's unconditional settings lookup. Local MAT
% loading needs no database, account, credentials or network access.
file = fullfile(testCase.TestData.folder,'db_load_settings.m');
fid = fopen(file,'w'); fprintf(fid,'function value = db_load_settings; value = struct(); end\n'); fclose(fid);
addpath(testCase.TestData.folder);
progress = waitbar(0,'Import regression','Visible','off');
cleanup = onCleanup(@() delete(progress));
folders = cell(1,3); names = {'first','middle','last'};
for index = 1:3
    folders{index} = fullfile(testCase.TestData.folder,names{index}); mkdir(folders{index});
    cell_metrics = struct();
    cell_metrics.UID = [7 9]; cell_metrics.cellID = [1 2];
    cell_metrics.general.cellCount = 2; cell_metrics.general.basename = names{index};
    if index == 1
        cell_metrics.psth.flash = {[1;2],[3;4]};
        cell_metrics.general.psth.flash.x_bins = [0 1];
    elseif index == 2
        cell_metrics.psth.pulse = {[5;6],[7;8]};
        cell_metrics.general.psth.pulse.x_bins = [0 2];
    end
    save(fullfile(folders{index},[names{index},'.cell_metrics.cellinfo.mat']),'cell_metrics');
end
batch = loadCellMetricsBatch('basepaths',folders,'basenames',names,'waitbar_handle',progress);
verifyEqual(testCase,batch.psth.flash,{[1;2],[3;4],[],[],[],[]});
verifyEqual(testCase,batch.psth.pulse,{[],[],[5;6],[7;8],[],[]});
verifyEqual(testCase,batch.general.batch{1}.psth.flash.x_bins,[0 1]);
verifyEqual(testCase,batch.general.batch{2}.psth.pulse.x_bins,[0 2]);
ce.data.validateCellMetricsStruct(batch);
end

function records = read(testCase,kind)
records = ce.pipeline.importedCellFiles(testCase.TestData.session,kind,testCase.TestData.spikes);
end

function [metrics,results] = run(testCase,metrics)
[metrics,results] = ce.pipeline.runImportedStages(metrics,testCase.TestData.spikes, ...
    testCase.TestData.session,testCase.TestData.parameters);
end

function write(testCase,name,suffix,data)
variables.(name) = data;
save(fullfile(testCase.TestData.folder,['synthetic.',name,'.',suffix,'.mat']),'-struct','variables');
end

function value = mapFixture
value.UID = [7 9]; value.x_bins = (1:30)';
value.map = {20*exp(-((value.x_bins-15)/5).^2),zeros(30,1)};
end

function value = psthFixture
value.UID = [9 7]; value.unit = [1 2;3 4;5 6];
value.x_bins = [-1 0 1]; value.x_label = 'Time (s)'; value.boundaries = 0;
end
