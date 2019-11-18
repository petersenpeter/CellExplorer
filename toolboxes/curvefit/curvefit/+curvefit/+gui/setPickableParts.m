function setPickableParts(pickableElements, onOrOff)
% setPickableParts   changes the value for the PickableParts property if
% one exists in a array of handles.

if strcmp(onOrOff, 'on')
    set(pickableElements, 'PickableParts', 'visible')
else
    set(pickableElements, 'PickableParts', 'none')
end
end