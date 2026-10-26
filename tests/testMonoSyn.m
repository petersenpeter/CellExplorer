function tests = testMonoSyn
tests = functiontests(localfunctions);
end

function testReviewPreservedOnlyForMatchingDetection(testCase)
[automatic,origin] = fixture;
[mono,retained] = ce.curation.reconcileMonoSyn(struct(),automatic,origin);
verifyFalse(testCase,retained);
mono.sig_con = [1 2]; mono.sig_con_excitatory = [1 2];
mono.sig_con_inhibitory = zeros(0,2);
[reviewed,retained] = ce.curation.reconcileMonoSyn(mono,automatic,origin);
verifyTrue(testCase,retained);
verifyEqual(testCase,reviewed.sig_con,[1 2]);
verifyEmpty(testCase,reviewed.sig_con_inhibitory);
verifyEqual(testCase,reviewed.processinginfo.review.status,'external_selection_preserved');
[again,retained] = ce.curation.reconcileMonoSyn(reviewed,automatic,origin);
verifyTrue(testCase,retained);
verifyEqual(testCase,again,reviewed);
changed = origin; changed.inputHash = 'different interval';
[fresh,retained] = ce.curation.reconcileMonoSyn(reviewed,automatic,changed);
verifyFalse(testCase,retained);
verifyEqual(testCase,fresh.sig_con,automatic.sig_con_excitatory_all);
verifyEqual(testCase,fresh.processinginfo.review.status,'new_detection_previous_not_applied');
end

function testReviewCannotAddUnknownPairsOrDisagreeWithAlias(testCase)
[automatic,origin] = fixture;
mono = ce.curation.reconcileMonoSyn(struct(),automatic,origin);
mono.sig_con = [2 1]; mono.sig_con_excitatory = [2 1];
verifyError(testCase,@() ce.curation.validateMonoSynSelection(mono,automatic),'ce:curation:InvalidMonoSynSelection');
mono.sig_con = [];
verifyError(testCase,@() ce.curation.validateMonoSynSelection(mono,automatic),'ce:curation:InconsistentMonoSynAliases');
end

function testAutomaticProjectionIgnoresReviewFields(testCase)
[automatic,origin] = fixture;
mono = ce.curation.reconcileMonoSyn(struct(),automatic,origin);
before = ce.pipeline.fingerprint(ce.pipeline.monoSynAutomatic(mono));
mono.sig_con = []; mono.sig_con_excitatory = []; mono.manualEdit = true;
verifyEqual(testCase,ce.pipeline.fingerprint(ce.pipeline.monoSynAutomatic(mono)),before);
mono.ccgR(1) = 999;
verifyNotEqual(testCase,ce.pipeline.fingerprint(ce.pipeline.monoSynAutomatic(mono)),before);
end

function testInhibitoryOnlyMetricsAndEmptyReset(testCase)
[automatic,~] = fixture;
inputs = struct('selection',struct('excitatory',zeros(0,2),'inhibitory',[3 1]), ...
    'ccgR',automatic.ccgR,'binSize',automatic.binSize,'total',automatic.n,'UID',[1 2 3]);
settings = struct('randomSeed',0,'convolutionWindow',.020);
definition = ce.pipeline.stageDefinition('monosynaptic_metrics');
[metrics,result] = ce.pipeline.runStage(struct(),definition,inputs,settings,@() ce.pipeline.stages.monoSynMetrics(inputs,settings));
assertEqual(testCase,result.status,'completed',result.error.message);
verifyEqual(testCase,metrics.putativeConnections.inhibitory,[3 1]);
verifyEqual(testCase,metrics.synapticEffect,{'Unknown','Unknown','Inhibitory'});
verifyEqual(testCase,metrics.synapticConnectionsIn,[0 0 0]);
verifyEqual(testCase,metrics.putativeConnections.inhibitoryTransProb, ...
    ce_GetTransProb(automatic.ccgR(:,3,1),automatic.n(3),automatic.binSize,.020));
inputs.selection.inhibitory = zeros(0,2);
[metrics,result] = ce.pipeline.runStage(metrics,definition,inputs,settings,@() ce.pipeline.stages.monoSynMetrics(inputs,settings));
verifyEqual(testCase,result.status,'completed');
verifyEqual(testCase,metrics.synapticEffect,{'Unknown','Unknown','Unknown'});
verifyFalse(testCase,isfield(metrics.putativeConnections,'inhibitoryTransProb'));
end

function testExcitatoryCountsAndTransmission(testCase)
[automatic,~] = fixture;
inputs = struct('selection',struct('excitatory',[1 2;1 3],'inhibitory',zeros(0,2)), ...
    'ccgR',automatic.ccgR,'binSize',automatic.binSize,'total',automatic.n,'UID',[1 2 3]);
metrics = ce.pipeline.stages.monoSynMetrics(inputs,struct('convolutionWindow',.020));
verifyEqual(testCase,metrics.synapticConnectionsOut,[2 0 0]);
verifyEqual(testCase,metrics.synapticConnectionsIn,[0 1 1]);
for index = 1:2
    verifyEqual(testCase,metrics.putativeConnections.excitatoryTransProb(index), ...
        ce_GetTransProb(automatic.ccgR(:,1,index+1),automatic.n(1),automatic.binSize,.020));
end
end

function testArchivePreservesExactFileAndRejectsInterveningEdits(testCase)
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
file = fullfile(folder,'synthetic.mono_res.cellinfo.mat');
mono_res = struct('sig_con',[1 2]); save(file,'mono_res'); % Legacy file, no provenance.
before = ce.pipeline.fileFingerprint(file);
replacement = struct('sig_con',[2 1]);
result = ce.io.saveMonoSyn(file,replacement,before);
verifyTrue(testCase,result.saved);
verifyEqual(testCase,ce.pipeline.fileFingerprint(result.backup),before);
current = ce.pipeline.fileFingerprint(file);
verifyError(testCase,@() ce.io.saveMonoSyn(file,mono_res,before),'ce:io:MonoSynRevisionChanged');
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),current);
result = ce.io.saveMonoSyn(file,replacement,current);
verifyFalse(testCase,result.saved);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),current);
end

function testFailedBackupPreservesExistingFile(testCase)
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
file = fullfile(folder,'synthetic.mono_res.cellinfo.mat');
mono_res = struct('sig_con',[1 2]); save(file,'mono_res');
before = ce.pipeline.fileFingerprint(file);
fid = fopen(fullfile(folder,'revisions_mono_res'),'w'); fclose(fid);
failed = false;
try
    ce.io.saveMonoSyn(file,struct('sig_con',[2 1]),before);
catch
    failed = true;
end
verifyTrue(testCase,failed);
verifyEqual(testCase,ce.pipeline.fileFingerprint(file),before);
end

function [automatic,origin] = fixture
automatic = struct('ccgR',20*ones(301,3,3),'n',[1000 1200 900],'Pred',[], ...
    'Bounds',[],'completeIndex',[1 11 1;1 12 2;2 13 3],'binSize',.0004, ...
    'duration',.120,'conv_w',25,'Pcausal',nan(3),'sig_con_excitatory_all',[1 2;1 3], ...
    'sig_con_inhibitory_all',[3 1]);
automatic.ccgR(156,1,2) = 60;
origin = struct('schemaVersion',1,'stageVersion',1,'definitionHash','definition', ...
    'inputHash','inputs','parameterHash','settings','implementationHash','code', ...
    'environmentHash','environment','outputHash',ce.pipeline.fingerprint(automatic),'createdAt',now);
end
