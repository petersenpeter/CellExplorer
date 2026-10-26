function tests=testBinaryViewerIO
tests=functiontests(localfunctions);
end
function setup(t)
t.TestData.folder=tempname; mkdir(t.TestData.folder);
t.TestData.readers=ce.io.OwnedFileReaders;
end
function teardown(t)
t.TestData.readers.close(); rmdir(t.TestData.folder,'s');
end
function testPrecisionAndExactWindows(t)
names={'int8','uint8','int16','uint16','int32','uint32','int64','uint64','single','double'};
widths=[1 1 2 2 4 4 8 8 4 8];
for k=1:numel(names)
    precision=names{k}; expected=reshape(1:120,3,40)';
    file=fullfile(t.TestData.folder,[precision,'.dat']);
    fid=fopen(file,'w'); fwrite(fid,expected',precision); fclose(fid);
    fid=t.TestData.readers.open('raw',file);
    verifyEqual(t,ce.io.binaryPrecision(precision),widths(k));
    fseek(fid,3,'bof'); verifyEqual(t,ce.io.binarySampleCount(fid,3,precision),40); verifyEqual(t,ftell(fid),3);
    [values,cache,read]=ce.io.readBinaryWindow(fid,3,precision,5,10);
    verifyEqual(t,values,expected(6:15,:)); verifyEqual(t,read,10);
    [values,cache,read]=ce.io.readBinaryWindow(fid,3,precision,8,10,cache);
    verifyEqual(t,values,expected(9:18,:)); verifyEqual(t,read,3);
    [values,cache,read]=ce.io.readBinaryWindow(fid,3,precision,4,10,cache);
    verifyEqual(t,values,expected(5:14,:)); verifyEqual(t,read,4);
    [values,cache,read]=ce.io.readBinaryWindow(fid,3,precision,4,10,cache);
    verifyEqual(t,values,expected(5:14,:)); verifyEqual(t,read,0);
    [values,~,read]=ce.io.readBinaryWindow(fid,3,precision,30,10,cache);
    verifyEqual(t,values,expected(31:40,:)); verifyEqual(t,read,10);
end
end
function testPartialFrameAndBounds(t)
file=fullfile(t.TestData.folder,'partial.dat'); fid=fopen(file,'w'); fwrite(fid,1:11,'int16'); fclose(fid);
fid=t.TestData.readers.open('raw',file);
[count,trailing]=ce.io.binarySampleCount(fid,3,'int16'); verifyEqual(t,count,3); verifyEqual(t,trailing,4);
verifyError(t,@() ce.io.readBinaryWindow(fid,3,'int16',2,2),'ce:io:ShortBinaryRead');
verifyError(t,@() ce.io.readBinaryWindow(fid,3,'int16',-.5,1),'MATLAB:expectedInteger');
verifyError(t,@() ce.io.binaryPrecision('2*int16'),'ce:io:UnsupportedPrecision');
verifyError(t,@() ce.io.binaryPrecision('int16=>single'),'ce:io:UnsupportedPrecision');
verifySize(t,ce.io.readBinaryWindow(fid,3,'int16',3,0),[0 3]);
end
function testGrowthInvalidatesCache(t)
file=fullfile(t.TestData.folder,'grow.dat'); fid=fopen(file,'w'); fwrite(fid,1:20,'int32'); fclose(fid);
fid=t.TestData.readers.open('raw',file);
[~,cache]=ce.io.readBinaryWindow(fid,2,'int32',0,5);
writer=fopen(file,'a'); fwrite(writer,21:24,'int32'); fclose(writer);
[values,~,read]=ce.io.readBinaryWindow(fid,2,'int32',0,5,cache);
verifyEqual(t,values,reshape(1:10,2,5)'); verifyEqual(t,read,5);
verifyEqual(t,ce.io.binarySampleCount(fid,2,'int32'),12);
end
function testOnlyOwnedHandlesClose(t)
file=fullfile(t.TestData.folder,'handles.dat'); fid=fopen(file,'w'); fwrite(fid,1:4); fclose(fid);
unrelated=fopen(file,'r'); cleanup=onCleanup(@() fclose(unrelated)); %#ok<NASGU>
first=t.TestData.readers.open('raw',file); second=t.TestData.readers.open('raw',file);
verifyFalse(t,ismember(first,fopen('all')) && first~=second);
t.TestData.readers.open('lfp',file); t.TestData.readers.close();
verifyTrue(t,ismember(unrelated,fopen('all')));
verifyEqual(t,fread(unrelated,1),1);
end
function testMissingAndAlreadyClosedReaders(t)
file=fullfile(t.TestData.folder,'handles.dat'); fid=fopen(file,'w'); fclose(fid);
fid=t.TestData.readers.open('raw',file); fclose(fid);
% Reopening after an external close must not close the new descriptor.
fid=t.TestData.readers.open('raw',file); verifyTrue(t,ismember(fid,fopen('all')));
verifyEqual(t,t.TestData.readers.open('raw',[file,'.missing']),-1);
end
