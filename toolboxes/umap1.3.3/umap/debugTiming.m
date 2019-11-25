function debugTiming(description)
DEBUGGING=false;
if DEBUGGING && ~isdeployed
    msg([description ' ' num2str(toc)], 40, ...
        'south west+', 'Timing test', 'none')
end
end