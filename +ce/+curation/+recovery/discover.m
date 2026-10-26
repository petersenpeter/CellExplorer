function candidates = discover(entry)
%DISCOVER Read this source's journals; malformed files remain untouched.
folder=fileparts(entry.file); [~,name]=fileparts(entry.source);
files=dir(fullfile(folder,[name,'.*.mat']));
[~,order]=sort([files.datenum],'descend'); files=files(order);
candidates=struct('file',{},'hash',{},'record',{},'error',{});
for index=1:numel(files)
    file=fullfile(files(index).folder,files(index).name);
    if strcmp(file,entry.file), continue; end
    candidate=struct('file',file,'hash','','record',[],'error','');
    try
        candidate.hash=ce.pipeline.fileFingerprint(file);
        loaded=load(file,'recovery');
        if ~isfield(loaded,'recovery') || ~isstruct(loaded.recovery) || ~isscalar(loaded.recovery) || ...
                ~isfield(loaded.recovery,'schemaVersion') || ~isequal(loaded.recovery.schemaVersion,1) || ...
                ~isfield(loaded.recovery,'source') || ~strcmp(loaded.recovery.source,entry.source)
            error('ce:recovery:InvalidJournal','Unsupported or mismatched recovery journal.');
        end
        ce.curation.verifyFileRevision(file,candidate.hash);
        candidate.record=loaded.recovery;
    catch exception
        candidate.error=exception.message;
    end
    candidates(end+1)=candidate;
end
end
