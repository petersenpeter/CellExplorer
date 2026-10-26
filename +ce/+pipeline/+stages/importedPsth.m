function patch = importedPsth(inputs)
%IMPORTEDPSTH Store one curve per cell in the viewer's existing PSTH container.
patch = struct();
for record = inputs.records
    data = record.data;
    patch.psth.(record.name) = num2cell(data.unit,1);
    patch.general.psth.(record.name) = rmfield(data,'unit');
end
end
