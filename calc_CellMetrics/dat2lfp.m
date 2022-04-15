function dat2lfp(session,show_waitbar)
% Creates a basename.lfp file from a basename.dat file (downsamples to 1250Hz)
%
% By Peter Petersen
% petersen.peter@gmail.com
% Last edited: 12-11-2019

if nargin<2
    show_waitbar = false;
end

basename = session.general.name;
basepath = session.general.basePath;
sr = session.extracellular.sr;
nChannels = session.extracellular.nChannels;

disp(['Creating ',basename,'.lfp file'])
fname = fullfile(basepath, [basename '.dat']);
fname_lfp = fullfile(basepath, [basename '.lfp']);
downsample_n = ceil(sr/1250); % 1250
MyFileInfo = dir(fname);
durationPerChunk = 5; % In seconds
nb_chunks = ceil(MyFileInfo.bytes/(sr*nChannels*2*durationPerChunk));
f = fopen(fname,'r');
lfp_file = fopen(fname_lfp,'w+');

if show_waitbar
    f_waitbar = waitbar(0,'','Name','Genering lfp file from raw data');
    h=findobj(f_waitbar,'Type','figure');
    ht = get(get(h,'currentaxes'),'title');
    set(ht,'interpreter','none')
    waitbar(0,f_waitbar,['Generating ',basename, '.lfp'],'interpreter','none');
end

for i = 1:nb_chunks
    if mod(i,50)==0
        if show_waitbar
            if ~ishandle(f_waitbar)
                warning('Canceled by user')
                return
            end
            waitbar(i/nb_chunks,f_waitbar,['Generating ',basename, '.lfp']);
        else
            if i~=50
                if ~show_waitbar
                    fprintf(repmat('\b',[1 length([num2str(round(50*(i-50)/nb_chunks)), ' percent'])]))
                end
            end
            fprintf('%d percent', round(50*i/nb_chunks));
        end
    end
    
    lfp2 = LoadBinaryChunk(f,'frequency',sr,'nChannels',nChannels,'channels',1:nChannels,'duration',durationPerChunk,'skip',0);
    lfp = downsample(lfp2,downsample_n);
    fwrite(lfp_file,lfp','int16');
end
if ishandle(f_waitbar)
    close(f_waitbar)
end
fclose(lfp_file);
fclose(f);
disp(['dat2lfp: ',basename,'.lfp file created successfully!'])
