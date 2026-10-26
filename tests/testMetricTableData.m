function tests = testMetricTableData
tests = functiontests(localfunctions);
end

function testMatchesLegacyColumnsExactly(testCase)
metrics.firingRate = [0 NaN Inf -Inf pi 1e-12];
metrics.UID = [1 10 99 1000 10000 100000];
metrics.animal = {'a','','long animal name','d','e','f'};
fields = {'firingRate';'UID';'animal'};
for blankNaNs = [false true]
    expected = cell(numel(fields),6);
    for index = 1:numel(fields)
        values = metrics.(fields{index});
        if isnumeric(values)
            formatted = string(values);
            if blankNaNs, formatted(isnan(values)) = ""; end
            expected(index,:) = cellstr(formatted);
        else
            expected(index,:) = cellstr(values);
        end
    end
    for cellIndex = 1:6
        verifyEqual(testCase,ce.ui.metricTableData(metrics,fields,cellIndex,blankNaNs), ...
            [fields,expected(:,cellIndex)]);
    end
end
end

function testReadsCurrentValuesAndPreservesRequestedOrder(testCase)
metrics.UID = [10 20]; metrics.rate = [1 2];
verifyEqual(testCase,ce.ui.metricTableData(metrics,{'rate','UID'},2),{'rate','2';'UID','20'});
metrics.rate(2) = 7;
verifyEqual(testCase,ce.ui.metricTableData(metrics,{'rate','UID'},2),{'rate','7';'UID','20'});
verifyEqual(testCase,ce.ui.metricTableData(metrics,{},2),cell(0,2));
end
