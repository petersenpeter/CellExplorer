function introPopUpCellExplorer
% CellExplorer first time user pop-up

buttonsText = {'CellExplorer.org','Intro video','UI elements','Group plots','Single cell plot','Keyboard shortcuts','Menu bar','Preferences','Customization','Tutorials'};
buttonsLink = {'https://cellexplorer.org/',...
    'https://www.youtube.com/watch?v=GR1glNhcGIY',...
    'https://cellexplorer.org/interface/description/',...
    'https://cellexplorer.org/interface/group-plots/',...
    'https://cellexplorer.org/interface/single-cell-plot-options/',...
    'https://cellexplorer.org/interface/keyboard-shortcuts/',...
    'https://cellexplorer.org/interface/menubar/',...
    'https://cellexplorer.org/interface/preferences/',...
    'https://cellexplorer.org/interface/custom-single-cell-plots/',...
    'https://cellexplorer.org/tutorials/tutorials/'...
    };

if isdeployed
    CellExplorer_path = pwd;
    return
else
    [CellExplorer_path,~,~] = fileparts(which('CellExplorer.m'));
    CellExplorer_path = fullfile(CellExplorer_path,'calc_CellMetrics');
end
img_data = imread(fullfile(CellExplorer_path,'CellExplorerIntro.png'));
img_rez = size(img_data); img_rez = img_rez([2,1]);

% Generating figure
UI.fig = figure('Name','Introduction to CellExplorer','Position',[50, 50, 160+img_rez(1), img_rez(2)+30],'NumberTitle','off','visible','off','DefaultTextInterpreter', 'none', 'DefaultLegendInterpreter', 'none', 'MenuBar', 'None','Color','w','Resize','off');
movegui(UI.fig,'center'), set(UI.fig,'visible','on')

UI.grid_panels = uix.Grid( 'Parent', UI.fig, 'Spacing', 5, 'Padding', 3); % Flexib grid box
UI.panel.left = uix.VBox('Parent',UI.grid_panels, 'Padding', 0); % Left panel
UI.panel.center = uix.VBox( 'Parent', UI.grid_panels, 'Padding', 0); % Center
set(UI.grid_panels, 'Widths', [150 -1],'MinimumWidths',[100 1]); % set grid panel size

UI.panel.title = uicontrol('Parent',UI.panel.center,'Style', 'text', 'String', 'Interface','ForegroundColor','w','HorizontalAlignment','center', 'fontweight', 'bold','Units','normalized','BackgroundColor',[0. 0.3 0.7],'FontSize',11);
UI.panel.main = uipanel('Parent',UI.panel.center,'BackgroundColor','w'); % Main plot panel
set(UI.panel.center, 'Heights', [20 -1]); % set center panel size

UI.panel.title2 = uicontrol('Parent',UI.panel.left,'Style', 'text', 'String', 'Links','ForegroundColor','w','HorizontalAlignment','center', 'fontweight', 'bold','Units','normalized','BackgroundColor',[0. 0.3 0.7],'FontSize',11);
for iTabs = 1:numel(buttonsText)
    uicontrol('Parent',UI.panel.left,'Style','pushbutton','Units','normalized','String',buttonsText{iTabs},'Callback',@openLinks);
end
uipanel('position',[0 0 1 1],'BorderType','none','Parent',UI.panel.left);
set(UI.panel.left, 'Heights', [20,32*ones(size(buttonsText)),-1],'MinimumHeights',[20,32*ones(size(buttonsText)),5],'Spacing', 3);

UI.image = axes('Parent',UI.panel.main);

image(UI.image,img_data);
set(UI.image,'Color','none','Units','Pixels'), hold on, axis off
UI.image.Position = [0 2 img_rez(1) img_rez(2)];
text(1,0,{'Click here to see image in higher resolution  '},'HorizontalAlignment','right','VerticalAlignment','bottom','ButtonDownFcn',@openImageLink, 'interpreter','tex','Units','normalized')

function openLinks(src,~)
    href_link = buttonsLink{strcmp(src.String,buttonsText)};
    web(href_link,'-new','-browser')
end

function openImageLink(~,~)
    web('https://buzsakilab.com/wp/wp-content/uploads/2020/05/CellExplorer_Figure3.png','-new','-browser')
end

end