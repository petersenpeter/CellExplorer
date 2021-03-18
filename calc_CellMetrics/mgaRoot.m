function path = mgaRoot
%MGAROOT Returns root path for mga toolbox folder

% store path persistently for repeat calls
persistent r
if isempty(r)
    r = fileparts(mfilename('fullpath'));
end % if
path = r;

end % mgaRoot