function cb = callback(func, varargin)
%CALLBACK Create a standard GUI event callback
%
%  cb = CALLBACK(FUNC) creates a standard callback for use in CFTool GUI
%  callbacks.  This callback will queue the execution of FUNC with other
%  callbacks created from this function.
%
%  cb = CALLBACK(FUNC, ARG1, ARG2, ...) creates a callback function that
%  will call FUNC(src, evtData, ARG1, ARG2, ...);

%  Copyright 2011 The MathWorks, Inc.

theQueue = curvefit.gui.event.EventQueue.getSharedQueue;
cb = theQueue.createCallback(func, varargin{:});
