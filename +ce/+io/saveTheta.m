function saved = saveTheta(file, theta, expectedHash)
%SAVETHETA Verified derived-cache replacement; reject intervening edits.
actual = '';
if isfile(file), actual = ce.pipeline.fileFingerprint(file); end
if ~strcmp(actual,expectedHash)
    error('ce:io:ThetaRevisionChanged','Theta cache changed since it was read: %s. Reload before saving.',file);
end
saved = false;
if ~isempty(actual)
    loaded = load(file,'InstantaneousTheta');
    if isfield(loaded,'InstantaneousTheta') && isequaln(loaded.InstantaneousTheta,theta), return; end
end
ce.io.writeMat(file,struct('InstantaneousTheta',theta));
saved = true;
end
