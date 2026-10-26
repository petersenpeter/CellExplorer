function patch = cellClass(input)
%CELLCLASS Align imported classifications independently of editable cell types.
patch = struct();
if input.available, patch.CellClassBuzcode = input.labels; end
end
