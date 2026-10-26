function tests = testViewerPreparation
tests = functiontests(localfunctions);
end

function setup(testCase)
folder=tempname; mkdir(folder); testCase.TestData.folder=folder; testCase.TestData.path=path;
root=fileparts(fileparts(mfilename('fullpath')));
copyfile(fullfile(root,'tests','fixtures','viewerDisplayLegacyReference.m.txt'),fullfile(folder,'viewerDisplayLegacyReference.m'));
addpath(folder);
end

function teardown(testCase)
path(testCase.TestData.path); rmdir(testCase.TestData.folder,'s');
end

function testSharedAxisMatchesFrozenLegacyExactly(testCase)
metrics=fixture; compare(testCase,metrics);
end

function testDifferentAxesUseEquivalentInterpolation(testCase)
metrics=fixture;
metrics.waveforms.time{2}=linspace(-.4,.4,33);
metrics.waveforms.filt{2}=sin(metrics.waveforms.time{2}*11);
metrics.waveforms.raw{2}=cos(metrics.waveforms.time{2}*7);
compare(testCase,metrics);
end

function testEmptyNanAndConstantWaveformsKeepLegacyConventions(testCase)
metrics=fixture;
metrics.waveforms.filt{1}=[]; metrics.waveforms.filt{2}(3)=NaN;
metrics.waveforms.filt{3}=zeros(size(metrics.waveforms.time{3}));
metrics.waveforms.raw{4}=[];
metrics.responseCurves.thetaPhase{2}=[];
metrics.responseCurves.thetaPhase{3}(1)=NaN;
actual=compare(testCase,metrics);
verifyEqual(testCase,actual.waveforms.filt_absolute(:,1:3),zeros(numel(actual.waveforms.time_zscored),3));
verifyTrue(testCase,all(isnan(actual.waveforms.filt_zscored(:,1:3)),'all'));
end

function testBatchPhaseUsesPerSessionAxis(testCase)
metrics=fixture;
metrics.general.batch={metrics.general,metrics.general};
metrics.batchIDs=[1 2 1 2 1];
metrics.general.batch{2}.responseCurves.thetaPhase.x_bins=linspace(-3,3,21);
compare(testCase,metrics);
end

function testSingleCellAndOptionalInputs(testCase)
metrics=fixture;
metrics.UID=metrics.UID(1); metrics.general.cellCount=1;
for key={'time','filt','raw'}, metrics.waveforms.(key{1})=metrics.waveforms.(key{1})(1); end
metrics.acg.wide=metrics.acg.wide(:,1); metrics.acg.narrow=metrics.acg.narrow(:,1);
metrics.acg=rmfield(metrics.acg,'log10'); metrics=rmfield(metrics,'isi');
metrics.responseCurves=struct(); metrics.waveforms=rmfield(metrics.waveforms,'raw');
compare(testCase,metrics);
end

function testCompleteLegacyDisplayCacheReused(testCase)
metrics=ce.ui.prepareDisplayData(fixture,[-3 -2 -1 0]); metrics.general.initialized=1;
metrics.waveforms.filt_zscored(:)=17;
compare(testCase,metrics);
end

function testPartialCacheRepaired(testCase)
original=fixture; expected=ce.ui.prepareDisplayData(original,[-3 -2 -1 0]);
original.general.initialized=1; original.waveforms.filt_absolute=zeros(3,5);
actual=ce.ui.prepareDisplayData(original,[-3 -2 -1 0]);
verifyEqual(testCase,actual.waveforms,expected.waveforms);
end

function testMalformedAxesAndWaveformDimensionsFailBeforeUIWork(testCase)
metrics=fixture; metrics.waveforms.time{1}=[0 0 1];
verifyError(testCase,@() ce.ui.prepareDisplayData(metrics,[-3 -2 -1 0]),'ce:ui:InvalidWaveformTime');
metrics=fixture; metrics.waveforms.filt{1}=1:3;
verifyError(testCase,@() ce.ui.prepareDisplayData(metrics,[-3 -2 -1 0]),'ce:ui:InvalidDisplayWaveform');
end

function testPreparationDoesNotOpenFiguresChangeCwdOrRng(testCase)
figures=findall(0,'Type','figure'); directory=pwd; state=rng;
ce.ui.prepareDisplayData(fixture,[-3 -2 -1 0]);
verifyEqual(testCase,findall(0,'Type','figure'),figures);
verifyEqual(testCase,pwd,directory); verifyEqual(testCase,rng,state);
end

function actual = compare(testCase,metrics)
[expected,bins]=viewerDisplayLegacyReference(metrics,[-3 -2 -1 0]);
[actual,actualBins]=ce.ui.prepareDisplayData(metrics,[-3 -2 -1 0]);
verifyEqual(testCase,actual,expected); verifyEqual(testCase,actualBins,bins);
end

function metrics = fixture
metrics.UID=7:11; metrics.general=struct('cellCount',5,'initialized',0);
metrics.waveforms.time=repmat({-.5:.025:.5},1,5);
for index=1:5
    time=metrics.waveforms.time{index};
    metrics.waveforms.filt{index}=sin(time*(index+3))*index;
    metrics.waveforms.raw{index}=cos(time*(index+2))*index;
    metrics.responseCurves.thetaPhase{index}=cos(linspace(-pi,pi,21))'+index;
end
metrics.general.responseCurves.thetaPhase.x_bins=linspace(-pi,pi,21);
metrics.acg=struct('wide',reshape(1:35,7,5),'narrow',reshape(1:15,3,5),'log10',reshape(1:15,3,5));
metrics.isi.log10=metrics.acg.log10+2;
end
