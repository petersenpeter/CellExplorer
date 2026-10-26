function [count, trailingBytes] = binarySampleCount(fid, channels, precision)
%BINARYSAMPLECOUNT Count complete interleaved frames without moving the reader.
validateattributes(channels,{'numeric'},{'scalar','integer','positive','finite'});
frameBytes=channels*ce.io.binaryPrecision(precision);
position=ftell(fid);
if position<0, error('ce:io:InvalidReader','Cannot query binary reader position.'); end
cleanup=onCleanup(@() fseek(fid,position,'bof'));
if fseek(fid,0,'eof')~=0, error('ce:io:SeekFailed','Cannot determine recording length.'); end
bytes=ftell(fid); count=floor(bytes/frameBytes); trailingBytes=rem(bytes,frameBytes);
end
