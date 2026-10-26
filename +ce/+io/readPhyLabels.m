function [ids, labels] = readPhyLabels(file, delimiter)
%READPHYLABELS Preserve label-table order and validate one label per cluster.
handle=fopen(file,'r');
if handle<0, error('ce:io:MissingSortingInput','Cannot open Phy labels: %s.',file); end
cleanup=onCleanup(@() fclose(handle));
header=fgetl(handle);
if ~ischar(header), ids=[]; labels={}; return; end
ids=[]; labels={};
while true
    line=fgetl(handle); if ~ischar(line), break; end
    if isempty(strtrim(line)), continue; end
    columns=strsplit(line,delimiter,'CollapseDelimiters',false);
    id=str2double(columns{1});
    if numel(columns)<2 || ~isfinite(id) || id<0 || id~=fix(id) || id>flintmax || isempty(strtrim(columns{2}))
        error('ce:io:InvalidPhyLabels','Expected nonnegative cluster ID and label in %s.',file);
    end
    ids(end+1,1)=id; labels{end+1,1}=strtrim(columns{2});
end
if numel(unique(ids))~=numel(ids)
    error('ce:io:InvalidPhyLabels','Duplicate cluster IDs in %s.',file);
end
end
