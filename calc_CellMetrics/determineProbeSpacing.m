function session = determineProbeSpacing(session)

%     % Loads probesVerticalSpacing and probesLayout from session struct
%     VerticalSpacing = session.analysisTags.probesVerticalSpacing;
%     Layout = session.analysisTags.probesLayout;
% else
% If no probesVerticalSpacing or probesLayout is given, it will try to load the information from the database


if ~isempty(session.extracellular.electrodes.siliconProbes)
    % Get the probe type from the session struct
    SiliconProbes = session.extracellular.electrodes.siliconProbes;
else
    % if no probe information is given in the session struct, it tries
    % to get the probe type from probe implants in the database
    probeimplants = struct2cell(db_load_table('probeimplants',session.animal.name));
    SiliconProbes = cellstr(string(probeimplants{1}.DynamicProbeLayout));
end

% Loads the list of silicon probes from the database
db_settings = db_load_settings;
options = weboptions('Username',db_settings.credentials.username,'Password',db_settings.credentials.password);
db_siliconprobes = webread([db_settings.address,'views/16742/'],options,'page_size','5000','descriptiveName',SiliconProbes{1});
if ~strcmp(db_siliconprobes.renderedHtml,'<div class="frm_no_entries">No Entries Found</div>')
    db_siliconprobes = loadjson(db_siliconprobes.renderedHtml);
else
    db_siliconprobes = [];
end

% Determines the best estimate of the vertical spacing across channels for different probe designs.
if ~isempty(db_siliconprobes)
    layout = db_siliconprobes{1}.layout;
    verticalSpacing = db_siliconprobes{1}.verticalSpacing;
    
    if any(strcmp(layout,{'staggered','poly2','poly 2','edge'}))
        VerticalSpacingBetweenSites_corrected = verticalSpacing/2;
    elseif strcmp(layout,{'linear'})
        VerticalSpacingBetweenSites_corrected = verticalSpacing;
    elseif any(strcmp(layout,{'poly3','poly 3'}))
        VerticalSpacingBetweenSites_corrected = verticalSpacing/3;
    elseif any(strcmp(layout,{'poly5','poly 5'}))
        VerticalSpacingBetweenSites_corrected = verticalSpacing/5;
    else
        error('No probe layout defined');
    end
    disp(['  Vertical spacing applied: ', num2str(VerticalSpacingBetweenSites_corrected),' µm'])
    session.analysisTags.probesVerticalSpacing = VerticalSpacingBetweenSites_corrected;
    session.analysisTags.probesLayout = layout;
end
