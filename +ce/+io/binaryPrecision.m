function bytes = binaryPrecision(precision)
%BINARYPRECISION Bytes per scalar for supported interleaved recording types.
if isstring(precision) && isscalar(precision), precision=char(precision); end
names={'int8','uint8','int16','uint16','int32','uint32','int64','uint64','single','double'};
sizes=[1 1 2 2 4 4 8 8 4 8];
if ~ischar(precision) || ~isrow(precision) || ~ismember(precision,names)
    error('ce:io:UnsupportedPrecision','Use a scalar recording type: %s.',strjoin(names,', '));
end
bytes=sizes(strcmp(names,precision));
end
