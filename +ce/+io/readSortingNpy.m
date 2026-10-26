function data = readSortingNpy(file)
%READSORTINGNPY Read supported numeric NPY v1 data with complete-frame checks.
% Keep the bundled reader's dtype/order conversion; reject unsupported versions
% rather than allowing its v1-only header decoder to misinterpret them.
handle=fopen(file,'rb');
if handle<0, error('ce:io:MissingSortingInput','Cannot open %s.',file); end
cleanup=onCleanup(@() fclose(handle));
prefix=fread(handle,8,'uint8=>uint8')';
if numel(prefix)~=8 || ~isequal(prefix(1:6),uint8([147 78 85 77 80 89])) || ~isequal(prefix(7:8),uint8([1 0]))
    error('ce:io:InvalidSortingData','Expected numeric NPY v1.0 data in %s.',file);
end
% Validate shape syntax before the bundled header reader's str2num conversion.
headerLength=fread(handle,1,'uint16',0,'ieee-le');
if isempty(headerLength), error('ce:io:InvalidSortingData','Truncated NPY header: %s.',file); end
header=fread(handle,headerLength,'*char')';
shape=regexp(header,'''shape''\s*:\s*\(([^)]*)\)','tokens','once');
if numel(header)~=headerLength || isempty(shape) || isempty(regexp(shape{1},'^\s*\d+\s*(,\s*\d+\s*)*,?\s*$','once'))
    error('ce:io:InvalidSortingData','Invalid NPY shape/header: %s.',file);
end
try
    [shape,type,~,~,offset]=readNPYheader(file);
    widths=struct('uint8',1,'int8',1,'logical',1,'uint16',2,'int16',2,'uint32',4,'int32',4,'single',4,'uint64',8,'int64',8,'double',8);
    info=dir(file);
    if ~isfield(widths,type) || any(~isfinite(shape) | shape<0 | shape~=fix(shape)) || ...
            info.bytes~=double(offset)+prod(shape)*widths.(type)
        error('ce:io:InvalidSortingData','Incomplete or extra NPY sample bytes: %s.',file);
    end
    data=readNPY(file);
catch exception
    error('ce:io:InvalidSortingData','Cannot read NPY data %s: %s',file,exception.message);
end
end
