function input = cellClassInput(session, spikes)
%CELLCLASSINPUT Read Buzcode labels by identity without modifying the source.
name = [session.general.name,'.CellClass.cellinfo.mat'];
file = fullfile(session.general.basePath,name);
input = struct('available',false,'file',name,'sha256','','UID',spikes.UID);
if isfield(spikes,'cluID'), input.cluID = spikes.cluID; end
if ~isfile(file), return; end
hash = ce.pipeline.fileFingerprint(file);
loaded = load(file,'CellClass');
if ~isfield(loaded,'CellClass') || ~isstruct(loaded.CellClass) || ~isscalar(loaded.CellClass)
    error('ce:pipeline:InvalidCellClass','%s must contain a scalar CellClass struct.',file);
end
source = loaded.CellClass;
[order,count] = ce.data.cellIdentityOrder(source,spikes,file,true);
if ~isfield(source,'label') || ~iscell(source.label) || ~isvector(source.label) || numel(source.label) ~= count
    error('ce:pipeline:InvalidCellClass','%s requires one label cell per source identity.',file);
end
labels = source.label(:)';
for index = 1:numel(labels)
    label = labels{index};
    if isempty(label)
        labels{index} = 'Unknown';
    elseif ~ischar(label) || ~isrow(label)
        error('ce:pipeline:InvalidCellClass','%s labels must be character rows or empty cells.',file);
    end
end
if ~strcmp(hash,ce.pipeline.fileFingerprint(file))
    error('ce:pipeline:CellImportChanged','Input changed while being read: %s.',file);
end
input.available = true; input.sha256 = hash; input.labels = labels(order);
end
