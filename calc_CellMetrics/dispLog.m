function dispLog(message,basename)
    % Part of CellExplorer
    if nargin<2
        basename = '';
    end
    timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
    message2 = sprintf('[%s: %s] %s', timestamp, basename, message);
    disp(message2);
end