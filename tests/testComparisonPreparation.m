function tests = testComparisonPreparation
tests = functiontests(localfunctions);
end

function setup(testCase)
folder=tempname; mkdir(folder); testCase.TestData.folder=folder; testCase.TestData.path=path;
root=fileparts(fileparts(mfilename('fullpath')));
copyfile(fullfile(root,'tests','fixtures','comparisonLegacyReference.m.txt'),fullfile(folder,'comparisonLegacyReference.m'));
addpath(folder);
end

function teardown(testCase)
path(testCase.TestData.path); rmdir(testCase.TestData.folder,'s');
end

function testReferencePreparationMatchesFrozenLegacyExactly(testCase)
compare(testCase,'reference',fixture);
end

function testGroundTruthPreparationMatchesFrozenLegacyExactly(testCase)
compare(testCase,'groundTruth',fixture);
end

function testMissingAndNanWaveformsPreserveComparisonConventions(testCase)
metrics=fixture; metrics.waveforms.filt{1}=[]; metrics.waveforms.raw{2}(1)=NaN;
compare(testCase,'reference',metrics);
end

function testPreparationDoesNotMutateEnvironment(testCase)
figures=findall(0,'Type','figure'); directory=pwd; randomState=rng;
compare(testCase,'reference',fixture);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
verifyEqual(testCase,pwd,directory); verifyEqual(testCase,rng,randomState);
end

function testNamedComparisonCachesValidateIdentity(testCase)
file=fullfile(testCase.TestData.folder,'comparison.mat'); metrics=fixture;
for name={'reference_cell_metrics','groundTruth_cell_metrics'}
    variables=struct(name{1},metrics,'UI','must not replace viewer state');
    save(file,'-struct','variables');
    verifyEqual(testCase,ce.io.readCellMetrics(file,name{1}),metrics);
    verifyError(testCase,@() ce.io.readCellMetrics(file),'ce:io:InvalidMetricsFile');
    variables.(name{1}).UID=[1 1 3]; save(file,'-struct','variables');
    verifyError(testCase,@() ce.io.readCellMetrics(file,name{1}),'ce:data:InvalidMetricIdentity');
end
verifyError(testCase,@() ce.io.readCellMetrics(file,'UI'),'ce:io:InvalidMetricVariable');
end

function compare(testCase,kind,metrics)
preferences=struct('cellTypes',{{'Unknown','Pyramidal','Interneuron'}}, ...
    'cellTypeColors',eye(3),'groundTruthColors',[1 0 0;0 0 1],'binCount',12);
UI.preferences=preferences; UI.params.ACGLogIntervals=[-3 -2 -1 0];
kernel=[1 2 1]'*[1 2 1]/16;
[expected,data,x,y]=comparisonLegacyReference(metrics,kind,UI,[200 600],[5 50],kernel);
[actual,actualData,actualX,actualY]=ce.ui.prepareComparisonData(metrics,kind,preferences, ...
    [200 600],[5 50],UI.params.ACGLogIntervals,kernel);
verifyEqual(testCase,actual,expected); verifyEqual(testCase,actualData,data);
verifyEqual(testCase,actualX,x); verifyEqual(testCase,actualY,y);
end

function metrics=fixture
metrics.UID=1:3; metrics.general.cellCount=3;
metrics.putativeCellType={'Pyramidal','Interneuron','Pyramidal'};
metrics.groundTruthClassification.PV=1:3;
metrics.troughToPeak=[.3 .4 .5]; metrics.acg_tau_rise=[10 20 30];
metrics.waveforms.time=repmat({-1:.2:1},1,3);
for index=1:3
    metrics.waveforms.filt{index}=sin(metrics.waveforms.time{index}*index);
    metrics.waveforms.raw{index}=cos(metrics.waveforms.time{index}*index);
end
metrics.acg=struct('wide',reshape(1:21,7,3),'narrow',reshape(1:9,3,3),'log10',reshape(2:10,3,3));
metrics.isi.log10=metrics.acg.log10+2;
end
