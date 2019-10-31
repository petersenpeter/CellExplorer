function str = ByteSize(in,typeIn)
% ByteSize calculates the memory usage of the provide variable.
% Source https://stackoverflow.com/questions/4845561/how-to-know-the-size-of-a-variable-in-matlab
if exist('typeIn','var')
    s = whos('-file',in);
else
    s = whos('in');
end
NumBytes = s.bytes;

scale = floor(log(NumBytes)/log(1024));
switch scale
    case 0
        str = [sprintf('%.0f',NumBytes) ' B'];
    case 1
        str = [sprintf('%.2f',NumBytes/(1024)) ' kB'];
    case 2
        str = [sprintf('%.2f',NumBytes/(1024^2)) ' MB'];
    case 3
        str = [sprintf('%.2f',NumBytes/(1024^3)) ' GB'];
    case 4
        str = [sprintf('%.2f',NumBytes/(1024^4)) ' TB'];
    case -inf
        % Size occasionally returned as zero (eg some Java objects).
        str = 'Not Available';
    otherwise
       str = 'Over a petabyte!!!';
end
