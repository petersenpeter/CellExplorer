function [data, cache, readSamples] = readBinaryWindow(fid, channels, precision, start, count, cache)
%READBINARYWINDOW Exact bounded read; start is a zero-based sample/frame offset.
% Output is samples-by-channels double, before any physical-unit conversion.
% Reuse only unchanged-file overlap; partial final frames are never returned.
if nargin<6, cache=[]; end
validateattributes(start,{'numeric'},{'scalar','integer','nonnegative','finite','<=',flintmax});
validateattributes(count,{'numeric'},{'scalar','integer','nonnegative','finite','<=',flintmax});
bytes=ce.io.binaryPrecision(precision); available=ce.io.binarySampleCount(fid,channels,precision);
if start+count>available
    error('ce:io:ShortBinaryRead','Requested samples [%g,%g) exceed %g complete recording samples.',start,start+count,available);
end
if (start+count)*channels*bytes>flintmax, error('ce:io:InvalidOffset','Byte offset exceeds exact integer precision.'); end
file=fopen(fid); info=dir(file); token=[info.bytes,info.datenum];
data=zeros(count,channels); readSamples=0;
valid=~isempty(cache) && isstruct(cache) && all(isfield(cache,{'fid','file','channels','precision','token','start','data'})) && ...
    isequal(cache.fid,fid) && strcmp(cache.file,file) && isequal(cache.channels,channels) && ...
    strcmp(cache.precision,precision) && isequal(cache.token,token) && size(cache.data,2)==channels;
first=start; last=start;
if valid
    first=max(start,cache.start); last=min(start+count,cache.start+size(cache.data,1));
    if last>first
        data(first-start+1:last-start,:)=cache.data(first-cache.start+1:last-cache.start,:);
    else, first=start; last=start; end
end
if first>start, data(1:first-start,:)=read(start,first-start); end
if last<start+count, data(last-start+1:end,:)=read(last,start+count-last); end
cache=struct('fid',fid,'file',file,'channels',channels,'precision',precision,'token',token,'start',start,'data',data);

    function value=read(offset,n)
        if fseek(fid,offset*channels*bytes,'bof')~=0, error('ce:io:SeekFailed','Cannot seek to sample %g.',offset); end
        [value,actual]=fread(fid,[channels,n],['*',char(precision)]);
        if actual~=channels*n, error('ce:io:ShortBinaryRead','Recording changed or ended during the window read.'); end
        value=double(value)'; readSamples=readSamples+n;
    end
end
