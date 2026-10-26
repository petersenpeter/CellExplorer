function record = thetaBehavior(session)
%THETABEHAVIOR Read only animal time/speed and verify their sampling contract.
record.file = [session.general.name,'.animal.behavior.mat'];
file = fullfile(session.general.basePath,record.file);
record.sha256 = ce.pipeline.fileFingerprint(file);
loaded = load(file,'animal');
if ~isfield(loaded,'animal') || ~isstruct(loaded.animal) || ~isscalar(loaded.animal) || ...
        ~all(isfield(loaded.animal,{'time','speed'}))
    error('ce:pipeline:InvalidThetaBehavior','%s must contain animal.time and animal.speed.',file);
end
record.time = loaded.animal.time; record.speed = loaded.animal.speed;
if ~isnumeric(record.time) || ~isreal(record.time) || ~isvector(record.time) || numel(record.time) < 2 || ...
        any(~isfinite(record.time(:))) || any(diff(record.time(:)) <= 0) || ...
        ~isnumeric(record.speed) || ~isreal(record.speed) || ~isvector(record.speed) || ...
        numel(record.speed) ~= numel(record.time) || any(isinf(record.speed(:)))
    error('ce:pipeline:InvalidThetaBehavior','Behavior needs strictly increasing finite time and matching speed samples (NaN speed is permitted).');
end
if ~strcmp(record.sha256,ce.pipeline.fileFingerprint(file))
    error('ce:pipeline:ThetaBehaviorChanged','Behavior changed while it was being read.');
end
end
