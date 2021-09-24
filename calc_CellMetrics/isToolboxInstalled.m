function output = isToolboxInstalled(toolboxname)
% toolboxname = 'Parallel Computing Toolbox';
installedToolboxes = ver;
installedToolboxes = {installedToolboxes.Name};
output = ismember(toolboxname,installedToolboxes);