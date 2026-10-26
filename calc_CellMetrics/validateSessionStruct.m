function validateSessionStruct(session)
%VALIDATESESSIONSTRUCT Display validation of session metadata (legacy entry point).
% For noninteractive use: report = ce.data.validateSession(session).
report = ce.data.validateSession(session);
ce.ui.showValidationReport(report);
end
