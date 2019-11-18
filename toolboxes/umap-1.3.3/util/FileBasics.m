%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%

classdef FileBasics<handle
    methods(Static)
        function [ok,errMsg, errId]=MkDir(folder)
            errMsg='';
            errId=0;
            if exist(folder, 'dir')
                ok=true;
            else
                [ok, errMsg,errId]=mkdir(folder);
                if ~ok
                    disp(errMsg);
                end
            end
        end
        function [folder, file]=UiPut(dfltFolder, dfltFile, ttl)
            if nargin<3
                ttl='Save to which folder & file?';
            end
            FileBasics.MkDir(dfltFolder);
            [~,~,ext]=fileparts(dfltFile);
            done=false;
            if ismac
                jd=FileBasics.MsgAtTopScreen(ttl);
            else
                jd=[];
            end
            [file, folder]=uiputfile(['*' ext], ttl, ...
                fullfile(dfltFolder, dfltFile));
            if ~isempty(jd)
                jd.dispose;
            end
            if isempty(folder) || isnumeric(folder)
                folder=[];
                file=[];
            end
        end
        
        function out=UiGet(clue, folder, ttl)
            out=[];
            if ismac
                jd=FileBasics.MsgAtTopScreen(ttl);
            else
                jd=[];
            end
            [file, fldr]=uigetfile(clue,ttl, [folder '/']);
            if ~isempty(jd)
                jd.dispose;
            end
            if ~isnumeric(file) && ~isnumeric(fldr)
                out=fullfile(fldr,file);
            end
            if isempty(out)
                return;
            end
            
        end
        function jd=MsgAtTopScreen(ttl, pauseSecs)
            if nargin<2
                pauseSecs=8;
            end
            pu=showMsg(ttl, 'Note...', 'north east++', false, false, pauseSecs);
            jd=pu.dlg;
            jd.setAlwaysOnTop(true);
            fig=get(0, 'currentFigure');
            if ~isempty(fig)
                [~,~,~,~,pe]=Gui.FindJavaScreen(gcf);
                jd.setLocation(pe.x+(pe.width/2)-100, pe.y);
            end
        end

    end
end