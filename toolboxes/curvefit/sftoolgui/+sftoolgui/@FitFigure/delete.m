function delete(this)
%delete Destroy an sftoolgui.FitFigure
%
%  delete(obj) destroys an instance of an sftoolgui.FitFigure.

%   Copyright 2012 The MathWorks, Inc.

% Inform the fits manager that the figure is closing
if isvalid(this.HSFTool)
    config = this.Configuration;
    config.Visible = 'off';
    this.HSFTool.HFitsManager.closeFit(this.FitUUID, config);
end

% Destroy the fitting panel: this is required to clean up listeners in Java
deletePanel(this.HFittingPanel);
