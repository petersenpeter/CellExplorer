function report=validateSessionMetadata(session)
%VALIDATESESSIONMETADATA Editor checks; an unsorted recording is permitted.
report=ce.data.validateSession(session,'checkFiles',false);
checks=report.checks;
if isstruct(session) && isscalar(session)
    if ~isfield(session,'spikeSorting') || isempty(session.spikeSorting)
        checks(strcmp({checks.code},'MissingSpikeSorting'))=[];
    end
    scalar('general.duration',false,true);
    scalar('extracellular.srLfp',false,false);
    scalar('extracellular.nSamples',true,true);
    precision('extracellular.precision',true);
    precision('extracellular.precisionLfp',false);
    name=get('general.name');
    if (ischar(name) || (isstring(name) && isscalar(name))) && ...
            (any(ismember(char(name),'/\')) || ismember(char(name),{'.','..'}))
        add('general.name','Use a session name without directory separators.');
    end
    n=get('extracellular.nChannels');
    for axis={'x','y','z'}
        field=['extracellular.chanCoords.',axis{1}]; value=get(field);
        if ~isempty(value) && (~isnumeric(value) || ~isreal(value) || ~isvector(value) || ...
                any(isinf(value)) || ~isequal(numel(value),n))
            add(field,'Provide one coordinate per recording channel (NaN for unknown sites), or leave empty.');
        end
    end
    scalar('extracellular.chanCoords.shankSpacing',false,true);
    scalar('extracellular.chanCoords.verticalSpacing',false,true);
    streams=get('timeSeries');
    if ~isempty(streams)
        if ~isstruct(streams) || ~isscalar(streams)
            add('timeSeries','Provide a scalar struct of named streams.');
        else
            for key=fieldnames(streams)'
                prefix=['timeSeries.',key{1},'.'];
                scalar([prefix,'nChannels'],true,false);
                scalar([prefix,'sr'],false,false);
                scalar([prefix,'nSamples'],true,true);
                scalar([prefix,'leastSignificantBit'],false,true);
                precision([prefix,'precision'],false);
            end
        end
    end
end
report=ce.data.validationReport(checks);
    function value=get(field)
        value=session;
        for part=strsplit(field,'.')
            if ~isstruct(value) || ~isscalar(value) || ~isfield(value,part{1}), value=[]; return; end
            value=value.(part{1});
        end
    end
    function scalar(field,integer,zeroAllowed)
        value=get(field); if isempty(value), return; end
        valid=isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value);
        if valid
            valid=value>0 || (zeroAllowed && value==0);
            if integer, valid=valid && value==fix(value); end
        end
        if ~valid, add(field,'Enter a finite scalar in the valid range (counts must be integers).'); end
    end
    function precision(field,required)
        value=get(field); if isempty(value) && ~required, return; end
        try, ce.io.binaryPrecision(value);
        catch, add(field,'Choose a supported scalar binary precision, such as int16, int32 or single.'); end
    end
    function add(field,message)
        checks(end+1)=struct('code','InvalidMetadata','path',field,'severity','error','message',message);
    end
end
