function [merged, conflicts] = mergeAnnotations(base, local, disk, choices)
%MERGEANNOTATIONS Three-way annotation merge in disk UID order, without I/O.
% Independent scalar edits and group memberships combine. Divergent values or
% deletion versus editing require one 'mine'/'disk' choice per reported conflict.
if nargin<4, choices={}; resolving=false; else, resolving=true; end
base=ce.curation.captureAnnotations(base,ce.curation.annotationOrder(disk,base,1:numel(base.UID)));
local=ce.curation.captureAnnotations(local,ce.curation.annotationOrder(disk,local,1:numel(local.UID)));
disk=ce.curation.captureAnnotations(disk);
merged=disk; conflicts=struct('field',{},'UID',{},'base',{},'local',{},'disk',{});
for key={'labels','deepSuperficial','deepSuperficialDistance','brainRegion','putativeCellType'}
    name=key{1}; b=node(base,name); l=node(local,name); d=node(disk,name);
    if b.present && l.present && d.present && strcmp(class(b.value),class(l.value)) && strcmp(class(l.value),class(d.value))
        result=d;
        for k=1:numel(disk.UID)
            value=choose(wrap(b.value(k)),wrap(l.value(k)),wrap(d.value(k)),name,disk.UID(k));
            result.value(k)=value.value;
        end
    else
        result=choose(b,l,d,name,[]);
    end
    merged=put(merged,name,result);
end
for key={'groups','tags','groundTruthClassification'}
    name=key{1}; b=node(base,name); l=node(local,name); d=node(disk,name);
    if b.present && l.present && d.present
        result=struct(); names=union(union(fieldnames(b.value),fieldnames(l.value)),fieldnames(d.value));
        for group=names'
            g=group{1}; bg=node(b.value,g); lg=node(l.value,g); dg=node(d.value,g);
            if lg.present && dg.present
                before=false(1,numel(disk.UID)); mine=before; theirs=before;
                if bg.present, before(bg.value)=true; end
                mine(lg.value)=true; theirs(dg.value)=true;
                % Boolean memberships cannot diverge in two different ways.
                combined=theirs; changed=mine~=before; combined(changed)=mine(changed);
                value=wrap(find(combined));
            else
                value=choose(bg,lg,dg,[name,'.',g],[]);
            end
            result=put(result,g,value);
        end
        merged.(name)=result;
    else
        merged=put(merged,name,choose(b,l,d,name,[]));
    end
end
if resolving && numel(choices)~=numel(conflicts)
    error('ce:curation:InvalidResolution','Provide exactly one choice per annotation conflict.');
end

    function result=choose(b,l,d,field,uid)
        if isequaln(l,b), result=d;
        elseif isequaln(d,b) || isequaln(l,d), result=l;
        else
            conflicts(end+1)=struct('field',field,'UID',uid,'base',b,'local',l,'disk',d);
            result=d;
            if resolving
                k=numel(conflicts);
                if ~iscell(choices) || numel(choices)<k || ~ismember(choices{k},{'mine','disk'})
                    error('ce:curation:InvalidResolution','Every conflict requires an explicit mine/disk choice.');
                end
                if strcmp(choices{k},'mine'), result=l; end
            end
        end
    end
end
function value=node(data,key)
value=struct('present',isfield(data,key),'value',[]);
if value.present, value.value=data.(key); end
end
function value=wrap(data)
value=struct('present',true,'value',[]); value.value=data;
end
function data=put(data,key,value)
if value.present, data.(key)=value.value;
elseif isfield(data,key), data=rmfield(data,key); end
end
