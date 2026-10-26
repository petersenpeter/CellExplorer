function settings = stageSettings(parameters, preferences, spikeSubset)
%STAGESETTINGS Effective time selection shared by the migrated metric stages.
settings.randomSeed = parameters.randomSeed;
settings.restrictToIntervals = parameters.restrictToIntervals;
settings.excludeIntervals = [];
if spikeSubset == 2, settings.excludeIntervals = parameters.excludeIntervals; end
settings.spikeSubset = spikeSubset;
settings.preferences = preferences;
end
