function values = parseNumericText(text, field, allowEmpty, allowMissing)
%PARSENUMERICTEXT Parse finite literals and colon ranges without evaluation.
% Accepted: whitespace/comma lists, semicolon-separated rows, [], a:b or a:s:b.
if nargin<2, field='value'; end
if nargin<3, allowEmpty=false; end
if nargin<4, allowMissing=false; end
% Missing coordinates may use NaN; rates, counts and indices never may.
if isstring(text) && isscalar(text), text=char(text); end
if ~ischar(text) || (~isempty(text) && ~isrow(text)), invalid; end
text=strtrim(text);
if startsWith(text,'[') && endsWith(text,']'), text=strtrim(text(2:end-1)); end
if isempty(text)
    if allowEmpty, values=[]; return; else, invalid; end
end
text=regexprep(text,'\s*:\s*',':');
rows=strsplit(text,';'); values=[]; total=0; width=[];
number='^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$';
for row=rows
    tokens=regexp(strtrim(row{1}),'[\s,]+','split'); rowValues=[];
    for token=tokens
    if allowMissing && strcmpi(token{1},'nan')
        rowValues(end+1)=nan; %#ok<AGROW>
        if total+numel(rowValues)>1e6, invalid; end
        continue
    end
    parts=strsplit(token{1},':');
    if numel(parts)>3 || any(cellfun(@(part) isempty(regexp(part,number,'once')),parts)), invalid; end
    nums=cellfun(@str2double,parts);
    if any(~isfinite(nums)), invalid; end
    if numel(nums)==1, next=nums;
    else
        step=1; if numel(nums)==3, step=nums(2); end
        if step==0, invalid; end
        n=max(0,floor((nums(end)-nums(1))/step)+1);
        if ~isfinite(n) || n>1e6, invalid; end
        next=nums(1):step:nums(end);
    end
    if total+numel(rowValues)+numel(next)>1e6, invalid; end
    rowValues=[rowValues,next]; %#ok<AGROW>
    end
    if ~isempty(width) && numel(rowValues)~=width, invalid; end
    width=numel(rowValues); total=total+width;
    values=[values;rowValues]; %#ok<AGROW>
end
if isempty(values) && ~allowEmpty, invalid; end
    function invalid
        error('ce:data:InvalidNumericText','%s: enter finite numbers or ranges such as 1:4 or 1:2:9.',field);
    end
end
