function spatialSplitterDegree = calc_spatialSplitterDegree(a,b)
% By Peter Petersen
    spatialSplitterDegree = sum(abs(a-b))/sum(a+b);
end
