function result = stageResult(name,status,reason)
%STAGERESULT A common schema for completed/reused/skipped/failed stage outcomes.
result = struct('name',name,'status',status,'reason',reason,'startedAt',now, ...
    'elapsedSeconds',0,'provenance',struct(),'error',struct('identifier','','message','','stack',[]));
end
