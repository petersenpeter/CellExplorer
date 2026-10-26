function writeMat(file, variables)
%WRITEMAT Save fields of a scalar struct as named MAT variables.
% Check staged names, classes and sizes without loading large recordings twice.
validateattributes(variables, {'struct'}, {'scalar'}, mfilename, 'variables');
info = whos('variables');
ce.io.writeAtomic(file, @write, @verify);

    function write(temporary)
        if info.bytes > 2e9
            save(temporary, '-struct', 'variables', '-v7.3', '-nocompression');
        else
            save(temporary, '-struct', 'variables');
        end
    end

    function verify(temporary)
        stored = whos('-file', temporary);
        names = fieldnames(variables);
        storedNames = {stored.name};
        if ~isequal(sort(storedNames(:)), sort(names))
            error('ce:io:VerificationFailed', 'Staged MAT variable names differ from the input.');
        end
        for index = 1:numel(stored)
            value = variables.(stored(index).name);
            if ~strcmp(stored(index).class, class(value)) || ~isequal(stored(index).size, size(value))
                error('ce:io:VerificationFailed', 'Staged MAT variable differs: %s.', stored(index).name);
            end
        end
    end
end
