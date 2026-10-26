function changedCells = remainingChanges(changedCells, batchIDs, savedSessions)
%REMAININGCHANGES Clear dirty cells only for sessions confirmed saved.
changedCells(ismember(batchIDs(changedCells), savedSessions)) = [];
end
