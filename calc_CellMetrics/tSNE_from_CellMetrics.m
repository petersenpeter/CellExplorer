function tSNE_metrics = tSNE_from_CellMetrics(cell_metrics,preferences,ce_waitbar,subset)
    
    % Default preferences
    % tSNE representation
    default_preferences.algorithm = 'tSNE';
    default_preferences.metrics = {'troughToPeak','ab_ratio','burstIndex_Royer2012','acg_tau_rise','firingRate'};
    default_preferences.dDistanceMetric = 'chebychev';
    default_preferences.exaggeration = 10;
    default_preferences.standardize = true;
    default_preferences.NumPCAComponents = 0;
    default_preferences.LearnRate = 1000;
    default_preferences.Perplexity = 30;
    default_preferences.InitialY = 'Random';
    
    % UMAP
    default_preferences.n_neighbors = 30;
    default_preferences.min_dist = 0.3;
    
    tSNE_metrics = {};
    if ~exist('preferences','var')
        preferences = {};
    end
    
    % validating preferences
    default_preferences_list = fieldnames(default_preferences);
    for i = 1:numel(default_preferences_list)
        if ~isfield(preferences,default_preferences_list{i})
            preferences.(default_preferences_list{i}) = default_preferences.(default_preferences_list{i});
        end
    end
    
    if ~exist('tSNE_preferences','var')
        ce_waitbar = [];
    end
    
    if ~exist('subset','var')
        subset = 1:cell_metrics.general.cellCount;
    end
    
    % Dropdown fields
    algorithms = {'tSNE','UMAP','PCA'};
    InitialYMetrics = {'Random','PCA space'};
    distanceMetrics = {'euclidean', 'seuclidean', 'cityblock', 'chebychev', 'minkowski', 'mahalanobis', 'cosine', 'correlation', 'spearman', 'hamming', 'jaccard'};
    
    [list_tSNE_metrics,ia] = generateMetricsList(cell_metrics,'all',preferences.metrics);
    
    % [indx,tf] = listdlg('PromptString',['Select the metrics to use for the tSNE plot'],'ListString',list_tSNE_metrics,'SelectionMode','multiple','ListSize',[350,400],'InitialValue',1:length(ia));
    
    load_tSNE.dialog = dialog('Position', [300, 300, 500, 518],'Name','Select metrics for dimensionality reduction','WindowStyle','modal','visible','off'); movegui(load_tSNE.dialog,'center'), set(load_tSNE.dialog,'visible','on')
    load_tSNE.sessionList = uicontrol('Parent',load_tSNE.dialog,'Style','listbox','String',list_tSNE_metrics,'Position',[10, 135, 480, 372],'Value',1:length(ia),'Max',100,'Min',1);
    
    uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 113, 100, 20],'Units','normalized','String','Algorithm','HorizontalAlignment','left');
    load_tSNE.popupmenu.algorithm = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[10, 95, 100, 20],'Units','normalized','String',algorithms,'HorizontalAlignment','left','Callback',@(src,evnt)setAlgorithm);
    if isfield(preferences,'algorithm') && find(strcmp(preferences.algorithm,algorithms))
        load_tSNE.popupmenu.algorithm.Value = find(strcmp(preferences.algorithm,algorithms));
    else
        load_tSNE.popupmenu.algorithm.Value = 1;
    end
            
    uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 113, 110, 20],'Units','normalized','String','Distance metric','HorizontalAlignment','left');
    load_tSNE.popupmenu.distanceMetric = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[120, 95, 120, 20],'Units','normalized','String',distanceMetrics,'HorizontalAlignment','left');
    load_tSNE.checkbox.filter = uicontrol('Parent',load_tSNE.dialog,'Style','checkbox','Position',[250, 95, 300, 20],'Units','normalized','String','Limit population to current filter','HorizontalAlignment','right');

    
%     tSNE_preferences.InitialY = 'Random';
    load_tSNE.label.NumPCAComponents = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 73, 100, 20],'Units','normalized','String','nPCAComponents','HorizontalAlignment','left');
    load_tSNE.popupmenu.NumPCAComponents = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[10, 55, 100, 20],'Units','normalized','String',preferences.NumPCAComponents,'HorizontalAlignment','left');
    
    load_tSNE.label.LearnRate = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 73, 90, 20],'Units','normalized','String','LearnRate','HorizontalAlignment','left');
    load_tSNE.popupmenu.LearnRate = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[120, 55, 90, 20],'Units','normalized','String',preferences.LearnRate,'HorizontalAlignment','left');
    
    load_tSNE.label.Perplexity = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[220, 73, 70, 20],'Units','normalized','String','Perplexity','HorizontalAlignment','left');
    load_tSNE.popupmenu.Perplexity = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[220, 55, 70, 20],'Units','normalized','String',preferences.Perplexity,'HorizontalAlignment','left');
    
    
    load_tSNE.label.InitialY = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[380, 73, 110, 20],'Units','normalized','String','InitialY','HorizontalAlignment','left');
    load_tSNE.popupmenu.InitialY = uicontrol('Parent',load_tSNE.dialog,'Style','popupmenu','Position',[380, 55, 110, 20],'Units','normalized','String',InitialYMetrics,'HorizontalAlignment','left','Value',1);
    if find(strcmp(preferences.InitialY,InitialYMetrics)); load_tSNE.popupmenu.InitialY.Value = find(strcmp(preferences.InitialY,InitialYMetrics)); end
    
    load_tSNE.label.exaggeration = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[300, 73, 70, 20],'Units','normalized','String','Exaggeration','HorizontalAlignment','left');
    load_tSNE.popupmenu.exaggeration = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[300, 55, 70, 20],'Units','normalized','String',num2str(preferences.exaggeration),'HorizontalAlignment','left');
    
    % UMAP Fields
    load_tSNE.label.n_neighbors = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[10, 73, 100, 20],'Units','normalized','String','n_neighbors','HorizontalAlignment','left');
    load_tSNE.popupmenu.n_neighbors = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[10, 55, 100, 20],'Units','normalized','String',preferences.n_neighbors,'HorizontalAlignment','left');
    
    load_tSNE.label.min_dist = uicontrol('Parent',load_tSNE.dialog,'Style','text','Position',[120, 73, 90, 20],'Units','normalized','String','min_dist','HorizontalAlignment','left');
    load_tSNE.popupmenu.min_dist = uicontrol('Parent',load_tSNE.dialog,'Style','Edit','Position',[120, 55, 90, 20],'Units','normalized','String',preferences.min_dist,'HorizontalAlignment','left');
    
    uicontrol('Parent',load_tSNE.dialog,'Style','pushbutton','Position',[300, 10, 90, 30],'String','OK','Callback',@(src,evnt)close_tSNE_dialog);
    uicontrol('Parent',load_tSNE.dialog,'Style','pushbutton','Position',[400, 10, 90, 30],'String','Cancel','Callback',@(src,evnt)cancel_tSNE_dialog);
    setAlgorithm
    uiwait(load_tSNE.dialog)
    
    function setAlgorithm
        if load_tSNE.popupmenu.algorithm.Value == 1
            distanceMetrics = {'euclidean', 'seuclidean', 'cityblock', 'chebychev', 'minkowski', 'mahalanobis', 'cosine', 'correlation', 'spearman', 'hamming', 'jaccard'};
            load_tSNE.popupmenu.distanceMetric.String = distanceMetrics;
            if find(strcmp(preferences.dDistanceMetric,distanceMetrics))
                load_tSNE.popupmenu.distanceMetric.Value = find(strcmp(preferences.dDistanceMetric,distanceMetrics)); 
            else
                load_tSNE.popupmenu.distanceMetric.Value = 1;
            end
            load_tSNE.popupmenu.distanceMetric.Enable = 'on';
            % t-SNE Fields
            load_tSNE.popupmenu.NumPCAComponents.Visible = 'on';
            load_tSNE.popupmenu.LearnRate.Visible = 'on';
            load_tSNE.popupmenu.Perplexity.Visible = 'on';
            load_tSNE.popupmenu.exaggeration.Visible = 'on';
            load_tSNE.popupmenu.InitialY.Visible = 'on';
            % t-SNE Labels
            load_tSNE.label.NumPCAComponents.Visible = 'on';
            load_tSNE.label.LearnRate.Visible = 'on';
            load_tSNE.label.Perplexity.Visible = 'on';
            load_tSNE.label.exaggeration.Visible = 'on';
            load_tSNE.label.InitialY.Visible = 'on';
            
            % UMAP
            load_tSNE.popupmenu.n_neighbors.Visible = 'off';
            load_tSNE.popupmenu.min_dist.Visible = 'off';
            load_tSNE.label.n_neighbors.Visible = 'off';
            load_tSNE.label.min_dist.Visible = 'off';
            
        elseif load_tSNE.popupmenu.algorithm.Value == 2
            distanceMetrics = {'euclidean', 'cosine', 'cityblock', 'seuclidean', 'squaredeuclidean', 'correlation', 'jaccard', 'spearman', 'hamming'};
            load_tSNE.popupmenu.distanceMetric.String = distanceMetrics;
            if find(strcmp(preferences.dDistanceMetric,distanceMetrics))
                load_tSNE.popupmenu.distanceMetric.Value = find(strcmp(preferences.dDistanceMetric,distanceMetrics)); 
            else
                load_tSNE.popupmenu.distanceMetric.Value = 1;
            end
            load_tSNE.popupmenu.distanceMetric.Enable = 'on';
            % t-SNE Fields
            load_tSNE.popupmenu.NumPCAComponents.Visible = 'off';
            load_tSNE.popupmenu.LearnRate.Visible = 'off';
            load_tSNE.popupmenu.Perplexity.Visible = 'off';
            load_tSNE.popupmenu.exaggeration.Visible = 'off';
            load_tSNE.popupmenu.InitialY.Visible = 'off';
            % t-SNE Labels
            load_tSNE.label.NumPCAComponents.Visible = 'off';
            load_tSNE.label.LearnRate.Visible = 'off';
            load_tSNE.label.Perplexity.Visible = 'off';
            load_tSNE.label.exaggeration.Visible = 'off';
            load_tSNE.label.InitialY.Visible = 'off';
            
            % UMAP
            load_tSNE.popupmenu.n_neighbors.Visible = 'on';
            load_tSNE.popupmenu.min_dist.Visible = 'on';
            load_tSNE.label.n_neighbors.Visible = 'on';
            load_tSNE.label.min_dist.Visible = 'on';
        else
            load_tSNE.popupmenu.distanceMetric.Enable = 'off';
            % t-SNE Fields
            load_tSNE.popupmenu.NumPCAComponents.Visible = 'off';
            load_tSNE.popupmenu.LearnRate.Visible = 'off';
            load_tSNE.popupmenu.Perplexity.Visible = 'off';
            load_tSNE.popupmenu.exaggeration.Visible = 'off';
            load_tSNE.popupmenu.InitialY.Visible = 'off';
            % t-SNE Labels
            load_tSNE.label.NumPCAComponents.Visible = 'off';
            load_tSNE.label.LearnRate.Visible = 'off';
            load_tSNE.label.Perplexity.Visible = 'off';
            load_tSNE.label.exaggeration.Visible = 'off';
            load_tSNE.label.InitialY.Visible = 'off';
            
            % UMAP
            load_tSNE.popupmenu.n_neighbors.Visible = 'off';
            load_tSNE.popupmenu.min_dist.Visible = 'off';
            load_tSNE.label.n_neighbors.Visible = 'off';
            load_tSNE.label.min_dist.Visible = 'off';
        end
    end
    
    function close_tSNE_dialog
        selectedFields = list_tSNE_metrics(load_tSNE.sessionList.Value);
        regularFields = find(~contains(selectedFields,'.'));
        X = cell2mat(cellfun(@(X) cell_metrics.(X),selectedFields(regularFields),'UniformOutput',false));
        
        structFields = find(contains(selectedFields,'.'));
        if ~isempty(structFields)
            for i = 1:length(structFields)
                newStr = split(selectedFields{structFields(i)},'.');
                X = [X;cell_metrics.(newStr{1}).(newStr{2})];
            end
        end
        
        preferences.metrics = list_tSNE_metrics(load_tSNE.sessionList.Value);
        preferences.dDistanceMetric = load_tSNE.popupmenu.distanceMetric.String{load_tSNE.popupmenu.distanceMetric.Value};
        preferences.exaggeration = str2double(load_tSNE.popupmenu.exaggeration.String);
        preferences.algorithm = load_tSNE.popupmenu.algorithm.String{load_tSNE.popupmenu.algorithm.Value};
        
        preferences.NumPCAComponents = str2double(load_tSNE.popupmenu.NumPCAComponents.String);
        preferences.LearnRate = str2double(load_tSNE.popupmenu.LearnRate.String);
        preferences.Perplexity = str2double(load_tSNE.popupmenu.Perplexity.String);
        preferences.InitialY = load_tSNE.popupmenu.InitialY.String{load_tSNE.popupmenu.InitialY.Value};
        
        preferences.n_neighbors = str2double(load_tSNE.popupmenu.n_neighbors.String);
        preferences.min_dist = str2double(load_tSNE.popupmenu.min_dist.String);
        
        preferences.filter = load_tSNE.checkbox.filter.Value;
        
        delete(load_tSNE.dialog);
        ce_waitbar = waitbar(0,'Preparing metrics for tSNE space...','WindowStyle','modal');
        X(isnan(X) | isinf(X)) = 0;
        if preferences.filter == 1
            X1 = nan(cell_metrics.general.cellCount,2);
            X = X(:,subset);
        end
        
        switch preferences.algorithm
            case 'tSNE'
                if strcmp(preferences.InitialY,'PCA space')
                    waitbar(0.1,ce_waitbar,'Calculating PCA init space...')
                    initPCA = pca(X,'NumComponents',2);
                    waitbar(0.2,ce_waitbar,'Calculating tSNE space...')
                    tSNE_metrics.plot = tsne(X','Standardize',preferences.standardize,'Distance',preferences.dDistanceMetric,'Exaggeration',preferences.exaggeration,'NumPCAComponents',preferences.NumPCAComponents,'Perplexity',preferences.Perplexity,'InitialY',initPCA,'LearnRate',preferences.LearnRate);
                else
                    waitbar(0.1,ce_waitbar,'Calculating tSNE space...')
                    tSNE_metrics.plot = tsne(X','Standardize',preferences.standardize,'Distance',preferences.dDistanceMetric,'Exaggeration',preferences.exaggeration,'NumPCAComponents',min(size(X,1),preferences.NumPCAComponents),'Perplexity',min(size(X,2),preferences.Perplexity),'LearnRate',preferences.LearnRate);
                end
                
            case 'UMAP'
                waitbar(0.1,ce_waitbar,'Calculating UMAP space...')
                tSNE_metrics.plot = run_umap(X','verbose','none','metric',preferences.dDistanceMetric,'n_neighbors',preferences.n_neighbors,'min_dist',preferences.min_dist); %
            case 'PCA'
                waitbar(0.1,ce_waitbar,'Calculating PCA space...')
                tSNE_metrics.plot = pca(X,'NumComponents',2); % ,'metric',tSNE_preferences.dDistanceMetric
        end
        tSNE_metrics.preferences = preferences;
        
        if preferences.filter == 1
            X1(subset,:) = tSNE_metrics.plot;
            tSNE_metrics.plot = X1;
        end
        
        if size(tSNE_metrics.plot,2)==1
            tSNE_metrics.plot = [tSNE_metrics.plot,tSNE_metrics.plot];
        end
        
        if ishandle(ce_waitbar)
            close(ce_waitbar)
        end
    end
    
    function  cancel_tSNE_dialog
        % Closes the dialog
        delete(load_tSNE.dialog);
        return
    end
    
end