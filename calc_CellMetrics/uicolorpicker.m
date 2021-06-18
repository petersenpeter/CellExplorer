function  RGB = uicolorpicker(colorIn,title1)
%% ReadMe
% ======== Information ========
% Version: MATLAB R2021a
% Toolbox Requirement: None
% External File Requirement: ColorPicker.html
% 
% Compilable uisetcolor function
%  
% ColorPicker.html content credit to:
% Muhammet Enginar (https://codepen.io/enginaryus/pen/xxZXwEx)
% 
%  Edit by Tim Yeh
% ========================
%
% Edited by Peter Petersen, May 2021:
% 1. Added color and title inputs
% 2. Center figure and return initial color on cancel

% Object initialization
app = [];
if nargin<1
    colorIn = [0,0,0];
    title1 = 'Color Picker';
elseif nargin<2
    title1 = 'Color Picker';
end
% Generate Visualize Components
createComponents

% Wait for user to click OK or cancel
waitfor(app.ColorPickerUIFigure)

% Output Data
RGB = app.RGB;


    function createComponents
        % Create properties
        
        app.RGB = colorIn;
        
        % Create ColorPickerUIFigure and hide until all components are created
        app.ColorPickerUIFigure = uifigure('Visible', 'off');
        app.ColorPickerUIFigure.AutoResizeChildren = 'off';
        app.ColorPickerUIFigure.Position = [100 100 261 364];
        app.ColorPickerUIFigure.Name = title1;
        app.ColorPickerUIFigure.Resize = 'off';
        
        % Create HTML
        app.HTML = uihtml(app.ColorPickerUIFigure);
        app.HTML.HTMLSource = 'ColorPicker.html';
        app.HTML.DataChangedFcn =  @HTMLDataChanged;
        app.HTML.Position = [7 185 250 143];
        
        % Create Button
        app.Button = uibutton(app.ColorPickerUIFigure, 'push');
        app.Button.Position = [31 71 202 32];
        app.Button.Text = '';
        app.Button.BackgroundColor = colorIn;
        
        % Create REditFieldLabel
        app.REditFieldLabel = uilabel(app.ColorPickerUIFigure);
        app.REditFieldLabel.HorizontalAlignment = 'center';
        app.REditFieldLabel.FontWeight = 'bold';
        app.REditFieldLabel.Position = [49 161 25 22];
        app.REditFieldLabel.Text = 'R';
        
        % Create RValue_EditField
        app.RValue_EditField = uieditfield(app.ColorPickerUIFigure, 'numeric');
        app.RValue_EditField.Limits = [0 255];
        app.RValue_EditField.ValueChangedFcn = @RValue_EditFieldValueChanged;
        app.RValue_EditField.HorizontalAlignment = 'center';
        app.RValue_EditField.Position = [34 140 55 22];
        app.RValue_EditField.Value = round(colorIn(1)*255);
        
        % Create GEditFieldLabel
        app.GEditFieldLabel = uilabel(app.ColorPickerUIFigure);
        app.GEditFieldLabel.HorizontalAlignment = 'center';
        app.GEditFieldLabel.FontWeight = 'bold';
        app.GEditFieldLabel.Position = [120 161 25 22];
        app.GEditFieldLabel.Text = 'G';
        
        % Create GValue_EditField
        app.GValue_EditField = uieditfield(app.ColorPickerUIFigure, 'numeric');
        app.GValue_EditField.Limits = [0 255];
        app.GValue_EditField.ValueChangedFcn = @GValue_EditFieldValueChanged;
        app.GValue_EditField.HorizontalAlignment = 'center';
        app.GValue_EditField.Position = [105 140 55 22];
        app.GValue_EditField.Value = round(colorIn(2)*255);
        
        % Create BEditFieldLabel
        app.BEditFieldLabel = uilabel(app.ColorPickerUIFigure);
        app.BEditFieldLabel.HorizontalAlignment = 'center';
        app.BEditFieldLabel.FontWeight = 'bold';
        app.BEditFieldLabel.Position = [190 161 25 22];
        app.BEditFieldLabel.Text = 'B';
        
        % Create BValue_EditField
        app.BValue_EditField = uieditfield(app.ColorPickerUIFigure, 'numeric');
        app.BValue_EditField.Limits = [0 255];
        app.BValue_EditField.ValueChangedFcn = @BValue_EditFieldValueChanged;
        app.BValue_EditField.HorizontalAlignment = 'center';
        app.BValue_EditField.Position = [175 140 55 22];
        app.BValue_EditField.Value = round(colorIn(3)*255);
        
        % Create OKButton
        app.OKButton = uibutton(app.ColorPickerUIFigure, 'push');
        app.OKButton.ButtonPushedFcn = @OKButtonPushed;
        app.OKButton.Position = [31 14 87 22];
        app.OKButton.Text = 'OK';
        
        % Create PreviewLabel
        app.PreviewLabel = uilabel(app.ColorPickerUIFigure);
        app.PreviewLabel.HorizontalAlignment = 'center';
        app.PreviewLabel.FontWeight = 'bold';
        app.PreviewLabel.Position = [32 102 51 22];
        app.PreviewLabel.Text = 'Preview';
        
        % Create CancelButton
        app.CancelButton = uibutton(app.ColorPickerUIFigure, 'push');
        app.CancelButton.ButtonPushedFcn = @CancelButtonPushed;
        app.CancelButton.Position = [146 14 87 22];
        app.CancelButton.Text = 'Cancel';
        
        % Center and show the figure after all components are created
        movegui(app.ColorPickerUIFigure,'center')
        app.ColorPickerUIFigure.Visible = 'on';
        
        %%
        function HTMLDataChanged(obj, event)
            data = app.HTML.Data;
            app.RGB = data'/255;
            app.Button.BackgroundColor = app.RGB;
            app.RValue_EditField.Value = data(1);
            app.GValue_EditField.Value = data(2);
            app.BValue_EditField.Value = data(3);
        end
        
        % Value changed function: RValue_EditField
        function RValue_EditFieldValueChanged(obj, event)
            manualSetupRGB
        end
        
        % Value changed function: GValue_EditField
        function GValue_EditFieldValueChanged(obj, event)
            manualSetupRGB
        end
        
        % Value changed function: BValue_EditField
        function BValue_EditFieldValueChanged(obj, event)
            manualSetupRGB
        end
        
        % Button pushed function: OKButton
        function OKButtonPushed(obj, event)
            delete(app.ColorPickerUIFigure)
        end
        
        % Button pushed function: CancelButton
        function CancelButtonPushed(obj, event)
            app.RGB = colorIn;
            delete(app.ColorPickerUIFigure)
        end
        
        function manualSetupRGB
            R = app.RValue_EditField.Value;
            G = app.GValue_EditField.Value;
            B = app.BValue_EditField.Value;
            app.RGB = [R,G,B]/255;
            app.Button.BackgroundColor = app.RGB;
        end
    end
end