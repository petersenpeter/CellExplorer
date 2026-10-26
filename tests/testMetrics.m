function tests = testMetrics
tests = functiontests(localfunctions);
end

function testGiniReferenceValues(testCase)
verifyEqual(testCase,ce.metrics.calc_gini(ones(1,100)),0,'AbsTol',1e-14);
verifyEqual(testCase,ce.metrics.calc_gini([zeros(1,99),1]),99/101,'AbsTol',1e-14);
verifyEqual(testCase,calc_gini([1 2 4]),ce.metrics.calc_gini([1 2 4]));
end

function testSpatialSplitterReferenceValues(testCase)
verifyEqual(testCase,ce.metrics.calc_spatialSplitterDegree([1 0],[0 1]),1);
verifyEqual(testCase,ce.metrics.calc_spatialSplitterDegree([1 2],[1 2]),0);
verifyEqual(testCase,calc_spatialSplitterDegree([1 2],[3 4]),0.4,'AbsTol',1e-14);
end

function testLogIsiMassAndCompatibility(testCase)
times = {[0 .01 .03 .07],[0 .02 .06]};
actual = ce.metrics.calc_logISIs(times,'showFigures',false);
widths = diff(10.^(-3:.04:1));
verifyEqual(testCase,widths * actual.log10,[3/4 2/3],'AbsTol',1e-12);
verifyEqual(testCase,calc_logISIs(times,'showFigures',false),actual);
end

function testWaveformCompatibility(testCase)
time = (-32:31)/40;
spikes.timeWaveform = {time};
spikes.filtWaveform = {-exp(-(time/.08).^2)+.5*exp(-((time-.3)/.1).^2)};
actual = ce.metrics.calc_waveform_metrics(spikes,40000,'showFigures',false);
verifyEqual(testCase,calc_waveform_metrics(spikes,40000,'showFigures',false),actual);
verifyGreaterThan(testCase,actual.troughtoPeak,0);
verifyLessThan(testCase,actual.troughtoPeak,1);
end

function testLegacyValidationEntryPoint(testCase)
metrics.general.cellCount = 2;
metrics.UID = [1 2];
metrics.firingRate = [2 3];
metrics.waveforms = struct(); % Empty optional plot data must not crash validation.
validateCellMetricsStruct(metrics);
ce.data.validateCellMetricsStruct(metrics);
metrics.firingRate = [2;3];
verifyError(testCase,@() ce.data.validateCellMetricsStruct(metrics),'');
end

function testLegacyFunctionSignatures(testCase)
verifyEqual(testCase,nargin('calc_gini'),1);
verifyEqual(testCase,nargout('calc_gini'),1);
verifyEqual(testCase,nargin('calc_spatialSplitterDegree'),2);
verifyEqual(testCase,nargout('validateCellMetricsStruct'),0);
verifyEqual(testCase,nargin('loadStruct'),-3);
verifyEqual(testCase,nargin('calc_waveform_metrics'),-3);
end
