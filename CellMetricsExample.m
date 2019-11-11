%% CellMetrics example: Deep-Superficial
IDs = [10985];
for iii = 1:length(IDs)
    disp(['*** Processing cells metrics: ', num2str(iii),' of ', num2str(length(IDs)),' sessions'])
    cell_metrics = calc_CellMetrics('id',IDs(iii),'metrics','DeepSuperficial','plots',true,'forceReload',true);
end

%% CellMetrics for Viktors data: stim sessions excluding stimulation windows
datasets_stim = {'ham5_769_batch','ham12_85_88-89_amp','ham12_92-95_amp','ham12_96-98_amp','ham21_33-35_amp','ham21_66-68_amp','ham21_106-108_amp','ham21_57-62_amp','ham21_113-115_amp','ham21_117-119_amp'}; %  1,5,6, Problem: 34, 2 (outlier)  % [1,3,4,5,6,7,8,32,33,35,39,49,58,59,60,63,64] 3,4  % 'ham5_769_batch','ham11_27-29_amp','ham12_102-104_amp',
datasets_stim2 = {'ham11_30-32_amp','ham11_34-36_amp','ham12_82-84_amp', 'ham12_153-155_amp', 'ham12_110-113_amp', 'ham12_114-117_amp','ham12_119-121_amp', 'ham12_139-140_142_amp', 'ham21_123-125_amp','ham21_92-94_amp', 'ham21_95-97_amp','ham21_102-105_amp'};
sessionNames = {'ham12_125-127_amp'};%[datasets_stim,datasets_stim2];  % Error 'ham11_30-32_amp'
sessionNames = {'R2W3_10A2_20191014','',''}
for iii = 1:length(sessionNames)
    disp(['*** Calculating cells metrics: ', sessionNames{iii},'. ', num2str(iii),' of ', num2str(length(sessionNames)),' sessions'])
    [session, basename, basepath, clusteringpath] = db_set_session('sessionName',sessionNames{iii});
    load('optogenetics.mat')
    NostimPeriods = [0,optogenetics.peak+0.5;optogenetics.peak-0.5,24*3600]';
    NostimPeriods(find(diff(NostimPeriods')<=0),:) = [];
    cell_metrics = calc_CellMetrics('session',sessionNames{iii},'timeRestriction',NostimPeriods,'saveAs','cell_metrics_excludeOpto','plots', false,'forceReload',true); % 'removeMetrics','DeepSuperficial', 'metrics',{'waveform_metrics'}
    drawnow
end
close all

%%
sessionsMS10  = {'Peter_MS10_170317_153237_concat','Peter_MS10_170314_163038','Peter_MS10_170315_123936','Peter_MS10_170307_154746_concat'};
sessionsMS12  = {'Peter_MS12_170717_111614_concat','Peter_MS12_170714_122034_concat','Peter_MS12_170715_111545_concat','Peter_MS12_170716_172307_concat','Peter_MS12_170719_095305_concat'};
sessionsMS13  = {'Peter_MS13_171130_121758_concat','Peter_MS13_171129_105507_concat','Peter_MS13_171110_163224_concat','Peter_MS13_171128_113924_concat','Peter_MS13_171201_130527_concat'};
sessionsMS14  = {'Peter_MS14_180122_163606_concat'};
sessionsMS18  = {'Peter_MS18_180519_120300_concat'};
sessionsMS21  = {'Peter_MS21_180808_115125_concat','Peter_MS21_180718_103455_concat', 'Peter_MS21_180629_110332_concat','Peter_MS21_180627_143449_concat','Peter_MS21_180719_155941_concat','Peter_MS21_180625_153927_concat','Peter_MS21_180628_155921_concat','Peter_MS21_180712_103200_concat'};
sessionsMS22  = {'Peter_MS22_180628_120341_concat','Peter_MS22_180629_110319_concat','Peter_MS22_180719_122813_concat','Peter_MS22_180711_112912_concat','Peter_MS22_180720_110055_concat'};
sessionsham05 = {'ham5_769_batch'};
sessionsham08 = {'ham8_191-192_amp'};
sessionsham11 = {'ham11_27-29_amp','ham11_34-36_amp'};
sessionsham12 = {'ham12_82-84_amp','ham12_85_88-89_amp','ham12_92-95_amp','ham12_96-98_amp','ham12_99-101_amp','ham12_102-104_amp','ham12_106_108-109_amp','ham12_110-113_amp','ham12_114-117_amp', 'ham12_119-121_amp', 'ham12_147-150_amp','ham12_153-155_amp','ham12_125-127_amp','ham12_139-140_142_amp'};
sessionsham20 = {'ham20_16-18_amp'};
sessionsham21 = {'ham21_18-22_amp','ham21_27-29_amp', 'ham21_33-35_amp','ham21_44-51_amp','ham21_57-62_amp','ham21_81-84_amp','ham21_85-87_amp','ham21_92-94_amp','ham21_95-97_amp','ham21_98-100_amp', 'ham21_102-105_amp', 'ham21_106-108_amp',  'ham21_109-111_amp', 'ham21_113-115_amp', 'ham21_117-119_amp','ham21_123-125_amp'};
sessionsham25 = {'ham25_35-37_amp','ham25_38-40_amp','ham25_41-43_amp','ham25_44-46_amp','ham25_47-49_amp','ham25_51-53_amp','ham25_58-60_amp','ham25_61-63_amp','ham25_64-66_amp','ham25_68_70-71_amp','ham25_72-74_amp'};
sessionsham26 = {'ham26_33-35_amp','ham26_55-57_amp'};
sessionsham31 = {'ham31_24-27_amp','ham31_103-110_amp','ham31_28-30_amp','ham31_31-34_amp','ham31_35-38_amp','ham31_42-45_amp'};
sessionsham34 = {'ham34_32-34_amp'}; % Problems with ham34_37-39_amp
sessionsTurtleSubject1 = {'PeterP-2013-09-04'};
sessionsGirardeauG = {'Rat08-20130708','Rat08-20130709','Rat08-20130710','Rat08-20130711','Rat08-20130712','Rat08-20130713'};
sessionsPVcells = {'20160225','20160309','20160308','20160307','20170301','20170203','20170124','20170125','20160210','20160505'};
sessionsTES = {'20190402_RF_EphysU_R02_session01'};
sessionsSenzaiY = {'YMV01_170818','YMV02_170815','YMV03_170818','YMV04_170907','YMV05_170912','YMV06_170913','YMV07_170914','YMV08_170922','YMV09_171204','YMV10_171213','YMV11_171208','YMV12_171211','YMV13_180127','YMV14_180128','YMV15_180205','YMV16_180206','YMV17_180207','YMV18_180208','YMV19_180209'};
sessionsValero = {'fNos6_190210_sess4'};
sessionsAxoAxonicCells = {'mouse1_180502b','mouse6_190331','mouse6_190330','mouse5_181116','mouse5_181112B','mouse3_180627','mouse3_180628','mouse3_180629','mouse4_181114b','mouse1_180415','mouse1_180414','mouse1_180501a','mouse1_180501b','mouse1_180502a'};

sessionNames = [sessionsMS10,sessionsMS12,sessionsMS13,sessionsMS14,sessionsMS18,sessionsMS21,sessionsMS22,sessionsham05,sessionsham08,sessionsham11,sessionsham12,sessionsham20,sessionsham21,sessionsham25,sessionsham26,sessionsham31,sessionsham34,sessionsTurtleSubject1,sessionsGirardeauG,sessionsPVcells,sessionsTES,sessionsSenzaiY,sessionsValero,sessionsAxoAxonicCells];
% sessionNames = [sessionsMS10,sessionsMS12,sessionsMS13,sessionsMS14,sessionsMS18,sessionsMS21,sessionsMS22];

cell_metrics = LoadCellMetricBatch('sessions',sessionNames);
cell_metrics = CellExplorer('metrics',cell_metrics);

%%
% sessionNames = sessionsAxoAxonicCells;
sessionNames = {'R2W3_10A2_20191014','R2W3_10A2_20191015','R2W3_10A2_20191016'};

for iii = 1:length(sessionNames)
    disp(['*** Calculating cells metrics: ', sessionNames{iii},'. ', num2str(iii),'/', num2str(length(sessionNames)),' sessions'])
%     cell_metrics = calc_CellMetrics('sessionStruct',session);
    cell_metrics = calc_CellMetrics('session',sessionNames{iii},'excludeManipulations',false,'submitToDatabase',true,'plots', false);
    % 'metrics',{'deepSuperficial'},
    % 'submitToDatabase',false,
    % 'forceReload',true   
    % 'plots', false
    % 'removeMetrics',{'deepSuperficial'},
    % 'excludeMetrics',{'monoSynaptic_connections'}
    drawnow, disp([' '])
%     close all
end

%% % load a subset of units fullfilling multiple of criterium

% Get cells that are assigned as 'Interneuron'
cell_metrics_idxs = loadCellMetrics('cell_metrics',cell_metrics,'putativeCellType',{'Interneuron'});

% Get cells that are has groundTruthClassification as 'Axoaxonic'
cell_metrics_idxs = loadCellMetrics('cell_metrics',cell_metrics,'groundTruthClassification',{'Axoaxonic'});

%% Get list of cell from a session labeled as Pyramidal cells
cell_metrics = LoadCellMetricBatch('sessions',{recording.name});
PyramidalIndexes = find(contains(cell_metrics.putativeCellType,'Pyramidal'));


%% % Running the Cell Explorer on your own data from a basepath

% 1. Define basepath of your dataset to run. This folder should contain at minimum a basename.dat and a basename.xml.
basepath = '/Volumes/buzsakilab/peterp03/IntanData/MS10/Peter_MS10_170307_154746_concat';
cd(basepath)

% 2. Generate session metadata struct using the template function
session = sessionTemplate;

% 3. Run the cell metrics pipeline 'calc_CellMetrics' using the session struct as input
cell_metrics = calc_CellMetrics('session', session);

% 4. Visualize the cell metrics in the Cell Explorer
cell_metrics = CellExplorer('metrics',cell_metrics);


%% % Open several session from paths

basenames = {'Rat08-20130708','Rat08-20130708'};
clusteringpaths = {'/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708','/Volumes/buzsakilab/Buzsakilabspace/Datasets/GirardeauG/Rat08/Rat08-20130708'};
cell_metrics = LoadCellMetricBatch('clusteringpaths',clusteringpaths,'basenames',basenames);
cell_metrics = CellExplorer('metrics',cell_metrics);

