function report = validationReport(checks)
%VALIDATIONREPORT Summarize machine-readable checks without displaying anything.
if nargin == 0
    checks = struct('code',{},'path',{},'severity',{},'message',{});
end
report.checks = checks;
report.errors = checks(strcmp({checks.severity},'error'));
report.warnings = checks(strcmp({checks.severity},'warning'));
report.valid = isempty(report.errors);
end
