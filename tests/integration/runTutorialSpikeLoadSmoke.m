function summary = runTutorialSpikeLoadSmoke(source)
%RUNTUTORIALSPIKELOADSMOKE Verify legacy cached loading on an isolated recording.
% The tutorial includes cached spikes, not original .clu/.res/.spk inputs.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
originalPath=path; pathCleanup=onCleanup(@() path(originalPath));
addpath(root,fullfile(root,'calc_CellMetrics'));
folder=tempname; mkdir(folder); cleanup=onCleanup(@() rmdir(folder,'s'));
basename=ce.io.basenameFromBasepath(source);
sourceFile=fullfile(source,[basename,'.spikes.cellinfo.mat']);
sourceHash=ce.pipeline.fileFingerprint(sourceFile);
loaded=load(fullfile(source,[basename,'.session.mat']),'session');
session=loaded.session; session.general.basePath=folder;
file=fullfile(folder,[basename,'.spikes.cellinfo.mat']); copyfile(sourceFile,file);
stored=load(file,'spikes'); before=ce.pipeline.fileFingerprint(file);
figures=findall(0,'Type','figure'); directory=pwd; randomState=rng;
actual=loadSpikes('session',session,'getWaveformsFromDat',false,'saveMat',false,'showWaveforms',false);
assert(isequaln(actual,stored.spikes),'Cached spike fields changed.');
assert(strcmp(before,ce.pipeline.fileFingerprint(file)));
assert(strcmp(sourceHash,ce.pipeline.fileFingerprint(sourceFile)));
assert(isequal(findall(0,'Type','figure'),figures)); assert(strcmp(pwd,directory)); assert(isequal(rng,randomState));
summary=struct('cells',numel(actual.UID),'allCachedFieldsEqual',true,'sourceUnchanged',true);
disp(summary);
end
