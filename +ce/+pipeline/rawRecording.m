function [recording, stamp] = rawRecording(session)
%RAWRECORDING Strict content identity for the interleaved raw recording.
% Reads the full file in bounded chunks; timestamps alone cannot establish reuse.
name = [session.general.name,'.dat'];
if isfield(session.extracellular,'fileName') && ~isempty(session.extracellular.fileName)
    name = session.extracellular.fileName;
end
file = fullfile(session.general.basePath,name);
before = dir(file);
if isempty(before) || before.isdir
    error('ce:pipeline:MissingRawData','Raw recording not found: %s',file);
end
if ~isfield(session.extracellular,'precision') || ~strcmp(session.extracellular.precision,'int16')
    error('ce:pipeline:UnsupportedRawPrecision','Managed waveform extraction currently requires int16 data; the legacy extractor assumes two bytes per sample.');
end
if before.bytes == 0 || mod(before.bytes,2*session.extracellular.nChannels) ~= 0
    error('ce:pipeline:InvalidRawSize','Raw recording size must contain complete interleaved channel frames.');
end
recording.sha256 = ce.pipeline.fileFingerprint(file);
after = dir(file);
if isempty(after) || before.bytes ~= after.bytes || before.datenum ~= after.datenum
    error('ce:pipeline:RawDataChanged','Raw recording changed while its content was being verified: %s',file);
end
recording.bytes = before.bytes;
stamp = struct('file',file,'bytes',before.bytes,'datenum',before.datenum);
end
