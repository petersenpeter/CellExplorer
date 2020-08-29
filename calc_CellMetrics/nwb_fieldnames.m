function out1 = nwb_fieldnames(nwb_info,nwb_path)
% Return list of fields for a nwb internal path

% By Peter Petersen
% petersen.peter@gmail.com

temp = strsplit(nwb_path,'/');
temp(cellfun(@isempty,temp)) = [];
nwb_relative = nwb_info;

for i = 1:numel(temp)
    groupID = ismember({nwb_relative.Groups.Name},['/',strjoin(temp(1:i),'/')]);
    nwb_relative = nwb_relative.Groups(groupID);
end
out1 = {nwb_relative.Datasets.Name};