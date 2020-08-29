function out1 = nwb_exist_path(nwb_info,nwb_path,nwb_field)
% Checks if a path exist in a HDF5 file recursively. Returns the depth of the path that exist

% By Peter Petersen
% petersen.peter@gmail.com

temp = strsplit(nwb_path,'/');
temp(cellfun(@isempty,temp)) = [];
groupID1 = ismember({nwb_info.Groups.Name},['/',temp{1}]);
nwb_relative = nwb_info;

out1 = 0;
if numel(temp)>5
    error('nwb_exist_path can only chech 5 levels deep into structure.');
end
if numel(temp)>=1 && any(groupID1)
    out1 = 1;
    nwb_relative = nwb_relative.Groups(groupID1);
    groupID2 = ismember({nwb_info.Groups(groupID1).Groups.Name},['/',temp{1},'/',temp{2}]);
    if any(groupID2)
        out1 = 2;
        nwb_relative = nwb_relative.Groups(groupID2);
        if numel(temp)>2
            groupID3 = ismember({nwb_info.Groups(groupID1).Groups(groupID2).Groups.Name},['/',temp{1},'/',temp{2},'/',temp{3}]);
            if any(groupID3)
                out1 = 3;
                nwb_relative = nwb_relative.Groups(groupID3);
                if numel(temp)>3
                    groupID4 = ismember({nwb_info.Groups(groupID1).Groups(groupID2).Groups(groupID3).Groups.Name},['/',temp{1},'/',temp{2},'/',temp{3},'/',temp{4}]);
                    if any(groupID4)
                        out1 = 4;
                        if numel(temp)>4
                            groupID5 = ismember({nwb_info.Groups(groupID1).Groups(groupID2).Groups(groupID3).Groups(groupID4).Groups.Name},['/',temp{1},'/',temp{2},'/',temp{3},'/',temp{4},'/',temp{5}]);
                            if numel(temp)>=5 && any(groupID5)
                                out1 = 5;
                                if numel(temp)>5
                                    groupID6 = ismember({nwb_info.Groups(groupID1).Groups(groupID2).Groups(groupID3).Groups(groupID4).Groups(groupID5).Groups.Name},['/',temp{1},'/',temp{2},'/',temp{3},'/',temp{4},'/',temp{5},'/',temp{6}]);
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

if exist('nwb_field','var') & out1 == numel(temp) & ismember({nwb_relative.Datasets.Name},nwb_field)
    out1 = out1+1;
end
if out1 < numel(temp)
    out1 = 0;
end
end