function dispLog(message,basename)
    % Part of CellExplorer
    timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
    if nargin<2
        message2 = sprintf('[%s] %s', timestamp, message);
    else
        message2 = sprintf('[%s: %s] %s', timestamp, basename, message);
    end
    disp(message2);
end