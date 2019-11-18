function newName = nameForDuplicate( sourceName, currentNames, theMessageCopy )
% nameForDuplicate   Generate a name for new a duplicate
%
%   nameForDuplicate( sourceName, currentNames, theNounCopy )
%
%   Inputs
%       sourceName   Name of the thing to be duplicated
%       currentNames Cell-string of current names that the duplicate should not match
%       theNounCopy  A message that contains noun "copy" as its string. This
%           string will be appended to the source name to create the duplicate
%           name.

%   Copyright 2012 The MathWorks, Inc.

theNounCopy = getString( theMessageCopy );

baseName = iBaseFromSource( sourceName, theNounCopy );

% Append the noun "copy" and different integers to the base name until we find a
% name that is not in the list of current names.
count = 0;
while true
    count = count + 1;
    newName = sprintf( '%s %s %s', baseName, theNounCopy, int2str( count ) );
    
    if ~ismember( newName, currentNames )
        break
    end
end

end

function baseName = iBaseFromSource(sourceName,theNounCopy)
% iBaseFromSource   Extract the base name from the source name
%
% The base name is anything before "copy" or "copy <number>" that is at the end
% of the source name.

% We need to have a space before "copy"
exactlyOneSpace = ' ';
% The digits are optional, but if we have them then they should be preceded by a
% space.
optionalSpaceAndDigits = '( \d+)?';
% We are only interested in this pattern at the end of the string.
endOfString = '$';

% Look for this pattern in the source name and remove it (replace with empty) to
% generate the base name.
pattern = [exactlyOneSpace, theNounCopy, optionalSpaceAndDigits, endOfString];
baseName = regexprep( sourceName, pattern, '' );
end
