function basename = basenameFromBasepath(basepath)
    % Determines the basename from a basepath by scanning the directory for known files by the following order: 
    % 
    % 1.: *.session.mat
    % 2.: *.xml
    % 3.: *.lfp
    % 4.: *.dat
    % 5.: If no local files are detected it set the basename from the directory name
    %
    % Part of CellExplorer, by Peter Petersen
    
% Compatibility entry point; implementation: ce.io.basenameFromBasepath.
basename = ce.io.basenameFromBasepath(basepath);
end
