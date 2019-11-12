function dat2lfp(session)
% Creates a basename.lfp file from a basename.dat file (downsamples to 1250Hz)
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 12-11-2019

basename = session.general.name;
basepath = session.general.basePath;
sr = session.extracellular.sr;
nChannels = session.extracellular.nChannels;

disp(['Creating ',basename,'.lfp file'])
fname = fullfile(basepath, [basename '.dat']);
fname_eeg = fullfile(basepath, [basename '.lfp']);
downsample_n = ceil(sr/1250); % 1250
MyFileInfo = dir(fname);
durationPerChunk = 5; % In seconds
nb_chunks = ceil(MyFileInfo.bytes/(sr*nChannels*2*durationPerChunk));
f = fopen(fname,'r');
eeg_file = fopen(fname_eeg,'w+');

for i = 1:nb_chunks
        if mod(i,100)==0
            if i~=100
                fprintf(repmat('\b',[1 length([num2str(round(100*(i-100)/nb_chunks)), ' percent'])]))
            end
            fprintf('%d percent', round(100*i/nb_chunks));
        end
    lfp2 = LoadBinaryChunk(f,'frequency',sr,'nChannels',nChannels,'channels',1:nChannels,'duration',durationPerChunk,'skip',0);
    lfp = downsample(lfp2,downsample_n);
    fwrite(eeg_file,lfp','int16');
end
fclose(eeg_file);
fclose(f);
disp(['dat2lfp: ',basename,'.lfp file created successfully!'])
