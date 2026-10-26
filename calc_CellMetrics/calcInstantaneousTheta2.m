function InstantaneousTheta = calcInstantaneousTheta2(session,varargin)
%CALC_INSTANTANEOUSTHETA2 Legacy direct-call theta API.
% Keeps historical cache/LFP creation defaults. Managed pipeline execution uses
% ce.pipeline.prepareTheta for provenance and deferred persistence instead.
InstantaneousTheta = ce.processing.calcInstantaneousTheta2(session,varargin{:});
end
