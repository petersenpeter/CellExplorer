function names = customCalculationNames
%CUSTOMCALCULATIONNAMES Preserve legacy package discovery and first-path order.
packages = what('customCalculations');
names = {};
if isempty(packages), return; end
files = packages(1).m;
for index = 1:numel(files)
    [~,name] = fileparts(files{index});
    if ~strcmpi(name,'template'), names{end+1} = name; end %#ok<AGROW>
end
end
