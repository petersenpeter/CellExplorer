function hash = fingerprint(value)
%FINGERPRINT SHA-256 of typed, dimensioned MATLAB values (struct fields sorted).
% Numeric bytes are exact, including NaNs. Unsupported objects fail explicitly.
% Native byte order is covered by the environment part of a stage cache key.
digest = java.security.MessageDigest.getInstance('SHA-256');
visit(value);
hash = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));

    function bytes(data)
        if ~isempty(data), digest.update(typecast(uint8(data(:)),'int8')); end
    end
    function token(text)
        encoded = unicode2native(text,'UTF-8');
        bytes(typecast(uint64(numel(encoded)),'uint8'));
        bytes(encoded);
    end
    function visit(data)
        token(class(data));
        token(mat2str(size(data)));
        if isstruct(data)
            names = sort(fieldnames(data));
            token(mat2str(numel(names)));
            for field = 1:numel(names), token(names{field}); end
            for element = 1:numel(data)
                for field = 1:numel(names), visit(data(element).(names{field})); end
            end
        elseif iscell(data)
            for element = 1:numel(data), visit(data{element}); end
        elseif isstring(data)
            visit(ismissing(data));
            data(ismissing(data)) = "";
            visit(cellstr(data));
        elseif ischar(data)
            bytes(typecast(uint16(data(:)),'uint8'));
        elseif isnumeric(data) || islogical(data)
            token(mat2str([issparse(data),isreal(data)]));
            if issparse(data)
                [rows,columns,values] = find(data);
                visit(rows); visit(columns); visit(values);
            elseif islogical(data)
                bytes(uint8(data));
            else
                bytes(typecast(real(data(:)),'uint8'));
                if ~isreal(data), bytes(typecast(imag(data(:)),'uint8')); end
            end
        else
            error('ce:pipeline:UnsupportedFingerprintType','Cannot fingerprint values of class %s.',class(data));
        end
    end
end
