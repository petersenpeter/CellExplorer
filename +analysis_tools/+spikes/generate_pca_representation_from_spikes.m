function out = generate_pca_representation_from_spikes(varargin)
% This is a wrapper file for NeuroScope2 to calculate a PCA representation from the spikes data
% This function can be called from NeuroScope2 via the menu Analysis 

p = inputParser;

% The inputs are NeuroScope2 variables:
addParameter(p,'UI',[],@isstruct); % UI: struct with UI elements and settings of NeuroScope2
addParameter(p,'ephys',[],@isstruct); % ephys: Struct with ephys data for current shown time interval, e.g. ephys.raw (raw unprocessed data), ephys.traces (processed data)
addParameter(p,'data',[],@isstruct); % data: contains all external data loaded like data.session, data.spikes, data.events, data.states, data.behavior
parse(p,varargin{:})

ephys = p.Results.ephys;
UI = p.Results.UI;  
data = p.Results.data;

out = [];

% % % % % % % % % % % % % % % %
% Function content below
% % % % % % % % % % % % % % % % 

if isfield(data,'spikes') && isfield(data.spikes,'spindices')
    
    % Default parameters
    convolution_points = 50; % Number of convolution steps (gaussian convolution)
    convolution_stepsize = 0.002; % step size in seconds
    save_n_coefficients = 3; % Number of PCA coefficients to save
    variable_name = 'pca_coeffs'; % Variable name
    calculate_spikes_PCA_phases = false;

    content.title = 'Generate PCA representation from spikes'; % dialog title
    content.columns = 1; % 1 or 2 columns
    content.field_names = {'convolution_points','convolution_stepsize','save_n_coefficients','variable_name','calculate_spikes_PCA_phases'}; % name of the variables/fields
    content.field_title = {'Convolution points','Convolution stepsize (in seconds),','Number of coefficients to save?','Variable name','Calculate spikes PCA phases'}; % Titles shown above the fields
    content.field_style = {'edit','edit','edit','edit','checkbox'}; % popupmenu, edit, checkbox, radiobutton, togglebutton, listbox
    content.field_default = {convolution_points,convolution_stepsize,save_n_coefficients,variable_name,calculate_spikes_PCA_phases}; % default values
    content.format = {'numeric','numeric','numeric','char','logical'}; % char, numeric, logical (boolean)
    content.field_options = {'text','text','text','text','text'}; % options for popupmenus
    content.field_required = [true true true true false]; % field required?
    content.field_tooltip = {'Gaussian convolution point width','Convolution stepsize (seconds),','Number of coefficients to save?','Variable name','Calculate spikes PCA phases'};
    content = content_dialog(content);

    % Getting variables from content_dialog
    convolution_points = content.output{1};
    convolution_stepsize = content.output{2};    
    save_n_coefficients = content.output{3};
    variable_name = content.output{4};
    calculate_spikes_PCA_phases = content.output{5};

    % Checking if file already exist
    if exist(fullfile(data.session.general.basePath,[data.session.general.name,'.',variable_name,'.timeseries.mat']))
        answer = questdlg(['Overwrite existing ',variable_name,' file?'],'PCAs already calculated');
        if strcmp(answer,'Yes')
            run_analysis = true;
        else
            run_analysis = false;
        end
    else
        run_analysis = true;
    end

    %PCA analysis - trace convolution
    if content.continue && convolution_stepsize>0 && convolution_points > 0 && save_n_coefficients>=0 && save_n_coefficients<=data.spikes.numcells && run_analysis
        
        if ~isfield(data.spikes,'spindices')
            disp('Generating spindices')
            data.spikes.spindices = generateSpinDices(data.spikes.times);
        end

        disp('Convoluting spikes')
        [spikes_presentation,time_bins] = spikes_convolution(data.spikes,convolution_stepsize, convolution_points);

        % PCA reduction
        disp('Calculating PCA coefficients')
        [coeff,score,~,~,explained,~] = pca(spikes_presentation);
        % coeff : principal component coefficients, also known as loadings
        % score : principal component scores
        % latent : the principal component variances
        % explained : explained variance by each compoents

        % Plotting the explained variance
        figure, hold on
        bar(explained)
        plot(1:numel(explained), cumsum(explained), 'o-', 'MarkerFaceColor', 'r')
        title('Explained variance'),ylabel('Percentage'), xlabel('Coefficients')

        % coeff2 = spikes_presentation'*score;

        % Saving time series file (basename.variable_name.timeseries.mat)
        disp('Saving PCA coefficients')
        pca_coeffs = {};
        pca_coeffs.data = coeff(:,1:save_n_coefficients);
        pca_coeffs.timestamps = time_bins;
        pca_coeffs.sr = convolution_stepsize;

        saveStruct(pca_coeffs,'timeseries','session',data.session,'dataName',variable_name);


        %% Creating units by phase
        % Determining sorting by comparing the smoothed unit rates with the first/second PCA
        spikes = data.spikes;
        if calculate_spikes_PCA_phases
            disp('Calculating  spikes PCA phases')
            offset = [];
            for j = 1:spikes.numcells
                [r,lags] = xcorr(spikes_presentation(j,:)',coeff(:,1),500);
                [~,offset(j)] = max(r);
            end
            [~,sorting] = sort(offset);
            [~,sorting2] = sort(sorting);
            spikes.phase_of_PCA_1 = sorting2;

            if size(coeff,2)>1
                offset = [];
                for j = 1:spikes.numcells
                    [r,lags] = xcorr(spikes_presentation(j,:)',coeff(:,2),500);
                    [~,offset(j)] = max(r);
                end
                [~,sorting] = sort(offset);
                [~,sorting2] = sort(sorting);
                spikes.phase_of_PCA_2 = sorting2;
            end

            if size(coeff,2)>2
                offset = [];
                for j = 1:spikes.numcells
                    [r,lags] = xcorr(spikes_presentation(j,:)',coeff(:,3),500);
                    [~,offset(j)] = max(r);
                end
                [~,sorting] = sort(offset);
                [~,sorting2] = sort(sorting);
                spikes.phase_of_PCA_3 = sorting2;
            end
            disp('Saving PCA phases to spikes')
            saveStruct(spikes,'cellinfo','session',data.session); % Saving spikes
        end


        % Refreshing list of timeseries in NeuroScope2
        out.refresh.timeseries = true;
        out.refresh.spikes = true;

        disp('Successfully generated PCA representation from spikes')

        msgbox('Successfully generated PCA representation from spikes','NeuroScope2','help')
    end
else
    msgbox('Load spikes data before plotting the raster.','NeuroScope2','help')
end
