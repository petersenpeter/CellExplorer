function ce_savefigure(fig,savePathIn,fileNameIn,dispSave,saveFig1)
    % saveFig.path [1=summaryFigures,2=withCellExplorer,3=custom]
    % saveFig.fileFormat [1=png,2=pdf]
    if nargin < 4
        dispSave = 0;
    end
    if nargin < 5
        saveFig1.save = 1;
        saveFig1.path = 1; 
        saveFig1.fileFormat = 1; 
    end
    
    if saveFig1.save
        if saveFig1.path == 1
            savePath = fullfile(savePathIn,'summaryFigures');
            if ~exist(savePath,'dir')
                mkdir(savePathIn,'summaryFigures')
            end
        elseif saveFig1.path == 2
            [dirName,~,~] = fileparts(which('CellExplorer.m'));
            savePath = fullfile(dirName,'summaryFigures');
            if ~exist(savePath,'dir')
                mkdir(dirName,'summaryFigures')
            end
        elseif saveFig1.path == 3
            if ~exist('dirNameCustom','var')
                dirNameCustom = uigetdir;
            end
            savePath = dirNameCustom;
        end
        if saveFig1.fileFormat == 1
            saveas(fig,fullfile(savePath,[fileNameIn,'.png']))
        else
            set(fig,'Units','Inches','Renderer','painters');
            pos = get(fig,'Position');
            set(fig,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)])
            print(fig, fullfile(savePath,[fileNameIn,'.pdf']),'-dpdf');
        end
        if exist('dispSave','var') && dispSave
            if saveFig1.fileFormat == 1
                disp(['Figure saved: ', fullfile(savePath,[fileNameIn,'.png'])])
            else
                disp(['Figure saved: ', fullfile(savePath,[fileNameIn,'.pdf'])])
            end
        end
    end
end