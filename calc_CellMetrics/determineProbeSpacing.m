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
    probeimplants = struct2cell(db_load_table('probeimplants',session.general.animal));
    SiliconProbes = cellstr(string(probeimplants{1}.DynamicProbeLayout));
end
probeids = [];
VerticalSpacingBetweenSites = [];
VerticalSpacingBetweenSites_corrected = [];
Layout = [];

% Loads the list of silicon probes from the database
siliconprobes = struct2cell(db_load_table('siliconprobes',SiliconProbes{1}));


% Determines the best estimate of the vertical spacing across channels for different probe designs.
for i =1:length(SiliconProbes)
    probeids(i) = find(arrayfun(@(n) strcmp(siliconprobes{n}.DescriptiveName, SiliconProbes{1}), 1:numel(siliconprobes)));
    VerticalSpacingBetweenSites(i) = str2num(siliconprobes{probeids(i)}.VerticalSpacingBetweenSites);
    Layout{i} = siliconprobes{probeids(i)}.Layout;
    if any(strcmp(Layout{i},{'staggered','poly2','poly 2','edge'}))
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i)/2;
    elseif strcmp(Layout{i},{'linear'})
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i);
    elseif any(strcmp(Layout{i},{'poly3','poly 3'}))
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i)/3;
    elseif any(strcmp(Layout{i},{'poly5','poly 5'}))
        VerticalSpacingBetweenSites_corrected(i) = VerticalSpacingBetweenSites(i)/5;
    else
        % If no probe design is provided, it assumes a staggered/poly2 layout (most common)
        error('No probe layout defined');
    end
end
if length(unique(VerticalSpacingBetweenSites_corrected))==1
    VerticalSpacing = VerticalSpacingBetweenSites_corrected(1);
else
    VerticalSpacing = VerticalSpacingBetweenSites_corrected;
end
disp(['Vertical spacing applied: ', num2str(VerticalSpacing),' µm'])
session.analysisTags.probesVerticalSpacing = VerticalSpacing;
session.analysisTags.probesLayout = Layout;

