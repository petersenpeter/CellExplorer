function [varargout] = prepareFittingData( varargin )
%PREPAREFITTINGDATA   Prepare data inputs for curve or surface fitting.
%
%   [OUT1, ..., OUTn] = PREPAREFITTINGDATA(IN1, ..., INn)
%
%   This function transforms data, if necessary, for the FIT function as
%   follows:
%
%       * Return data as columns regardless of the input shapes. Warn if sizes of
%       the inputs are different.
%
%       * Convert complex to real (remove imaginary parts) and warn.
%
%       * Remove NaN/Inf from data and warn.
%
%       * Convert non-double to double and warn.
%
%   This function assumes that data has already be checked to confirm that the
%   inputs all have the same number of elements. If they have differing number of
%   elements then behaviour is not guaranteed.
%
%   Data is converted from complex to real before NaN/Inf are removed. This
%   ensures that if a data point is NaN/Inf only in the imaginary component then
%   that point is not removed.

%   Copyright 2011 The MathWorks, Inc.

% The actions listed in the help are performed one at time with the output from
% one step being the input to the next step.
data = varargin;

iWarnIfSizeMismatch( data );

data = iEnsureColumns( data );
data = iEnsureDouble(  data );
data = iEnsureReal(    data );
data = iEnsureFinite(  data );

varargout = data;
end

function iWarnIfSizeMismatch( data )
% iWarnIfSizeMismatch   If the sizes of the data are not all the same, then
% warn the user

sizes = cellfun( @size, data, 'UniformOutput', false );
if ~isequal( sizes{:} )
    warning(message('curvefit:prepareFittingData:sizeMismatch'));
end
end

function data = iEnsureColumns( data )
% iEnsureColumns   Ensure that the data is arranged in column vectors
data = cellfun( @(c) c(:), data, 'UniformOutput', false );
end

function [data] = iEnsureDouble( data )
% iEnsureDouble   Ensure that the data is double. If it is not, convert it
% to double and warn the user

isDouble = cellfun( @iIsDouble, data );
if all( isDouble )
    % Nothing to do
else
    warning(message('curvefit:prepareFittingData:nonDouble'));
    data = cellfun( @double, data, 'UniformOutput', false );
end
end

function data = iEnsureReal( data )
% iEnsureReal   Ensure that data is real. If not, warn user and convert to real.

isDataReal = cellfun( @isreal, data );
if all( isDataReal )
    % nothing to do
else
    warning(message('curvefit:prepareFittingData:convertingComplexToReal'));
    data = cellfun( @real, data, 'UniformOutput', false );
end
end

function data = iEnsureFinite( data )
% iEnsureFinite   Ensure that data is finite. If there are any Inf or NaN values
% in the data, remove them and warn the user

% Find elements in each vector of data that are not NaN or Inf, i.e., that are 
% finite
isElementFinite = cellfun( @isfinite, data, 'UniformOutput', false );

% Find points (rows) that are finite across all data vectors
isRowFinite = isElementFinite{1};
for i = 2:numel( data )
    isRowFinite = isRowFinite & isElementFinite{i};
end

% If all rows have only finite values, ...
if all( isRowFinite )
    % ... then there is nothing to do
else
    % ... otherwise, we need to warn the user ...
    warning(message('curvefit:prepareFittingData:removingNaNAndInf'))
    % ... and keep only the finite rows.
    data = cellfun( @(c) c(isRowFinite), data, 'UniformOutput', false );
end
end

function tf = iIsDouble( vector )
% iIsDouble -- Test a vector to see if it is a double.
tf = isequal( class( vector ), 'double' );
end
