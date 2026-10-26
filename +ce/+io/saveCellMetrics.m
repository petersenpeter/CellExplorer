function saveCellMetrics(cell_metrics, file)
%SAVECELLMETRICS Replace the destination only after verifying staged output.
[~, ~, extension] = fileparts(char(file));
switch lower(extension)
    case '.mat'
        ce.io.writeMat(file, struct('cell_metrics', cell_metrics));
    case '.json'
        ce.io.writeJson(file, cell_metrics);
    case '.nwb'
        % MatNWB and its specifications remain in the legacy tree until their
        % format-specific migration has coverage.
        ce.io.writeAtomic(file, @(temporary) saveCellMetrics2nwb(cell_metrics, temporary), @verifyNwb);
    otherwise
        error('ce:io:UnsupportedFormat', 'Unsupported cell metrics file format: %s', file);
end
end

function verifyNwb(file)
h5info(file);
end
