classdef OwnedFileReaders < handle
    %OWNEDFILEREADERS Scope file handles to one viewer, including error cleanup.
    properties (Access=private)
        entries=struct('key',{},'fid',{},'file',{});
    end
    methods
        function fid=open(owner,key,file)
            owner.closeKey(key);
            fid=fopen(file,'rb');
            if fid>=0
                owner.entries(end+1)=struct('key',key,'fid',fid,'file',fopen(fid));
            end
        end
        function closeKey(owner,key)
            indices=find(strcmp({owner.entries.key},key));
            for index=indices
                item=owner.entries(index);
                try
                    if strcmp(fopen(item.fid),item.file), fclose(item.fid); end
                catch
                    % An external caller may already have closed this handle.
                end
            end
            owner.entries(indices)=[];
        end
        function close(owner)
            for key={owner.entries.key}, owner.closeKey(key{1}); end
        end
        function delete(owner)
            owner.close;
        end
    end
end
