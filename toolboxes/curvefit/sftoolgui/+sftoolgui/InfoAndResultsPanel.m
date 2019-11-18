classdef InfoAndResultsPanel < sftoolgui.Panel
%INFOANDRESULTSPANEL A SFTOOL panel for displaying information and results
%
%   INFOANDRESULTSSPANEL

%   Copyright 2008-2011 The MathWorks, Inc.
    
    properties(Access = private)
        JavaPanel
        JavaContainer
    end
    
    properties(Access = private, Constant)
        %Margin  Gap to apply around the java component
        Margin = 9;
    end
    
    methods
        function this = InfoAndResultsPanel(parentFig)
            this = this@sftoolgui.Panel(parentFig);
            
            this.JavaPanel = javaObjectEDT('com.mathworks.toolbox.curvefit.surfacefitting.SFInfoAndResultsPanel');
            
            [~, this.JavaContainer] = javacomponent(this.JavaPanel, [0  0 10 10], this.HUIPanel);
            set(this.JavaContainer, 'Units', 'pixels');
            
            this.layoutPanel();
        end
        
        function removeInfoPanel(this)
            javaMethodEDT('removeInfoPanel', this.JavaPanel);
        end
        
        function updateInfo(this, str, fitState)
            javaMethodEDT('updateInfo', this.JavaPanel, str, fitState);
        end
        
        function appendInfo(this, str, fitState)
            javaMethodEDT('appendInfo', this.JavaPanel, str, fitState);
        end
        
        function updateResults(this, str)
            javaMethodEDT('updateResults', this.JavaPanel, str);
        end
        
        function appendResults(this, str)
            javaMethodEDT('appendResults', this.JavaPanel, str);
        end
        
        % This should not be confused with the View setting (which appears
        % to remove the entire panel). This sets the java panel to be
        % invisible to reduce "flashing" and viewing intermediate states
        function setVisible(this, state)
            javaMethodEDT('setVisible', this.JavaPanel, state)
        end       
    end
    
    methods(Access = protected)
        function layoutPanel(this)
            % Pass on call to the superclass
            layoutPanel@sftoolgui.Panel(this);
            
            if ~isempty(this.JavaContainer)
                innerpos = this.InnerPosition;
                margin = this.Margin;
                
                % Add a margin around the java component
                pos = innerpos + [margin margin -2*margin -2*margin];
                
                % Clip the position rectangle to be within inner position
                pos = sftoolgui.util.clipPosition(innerpos, pos);
                
                % Apply correction
                pos = sftoolgui.util.adjustControlPosition(this.JavaContainer, pos);
                
                set(this.JavaContainer, 'Position', pos);
            end
        end
    end
end


