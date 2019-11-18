classdef(Sealed) Color
    % Color   Colors and colormap for Curve Fitting Tool.
    
    %   Copyright 2011-2014 The MathWorks, Inc.
    
    properties(Constant)
        % Blue   The shade of blue for Curve Fitting Tool
        Blue   = [ 18, 104, 179]/255;
        
        % Red   The shade of red for Curve Fitting Tool
        Red    = [237,  36,  38]/255;
        
        % Green   The shade of green for Curve Fitting Tool
        Green  = [155, 190,  61]/255;
        
        % Purple   The shade of purple for Curve Fitting Tool
        Purple = [123,  45, 116]/255;
        
        % Yellow   The shade of yellow for Curve Fitting Tool
        Yellow = [255, 199,   0]/255;
        
        % Azure   The shade of azure for Curve Fitting Tool
        Azure  = [ 77, 190, 238]/255;
    end
    
    methods(Access = private)
        function c = Color()
            % Color   Construction of this class is not allowed!
        end
    end
    
    methods(Static)
        function m = map( numRows )
            % map   The colormap for Curve Fitting Tool
            %
            %   sftoolgui.util.Color.map( M ) is an M-by-3 matrix
            %   containing the colormap for CFTOOL.
            %
            %   See also: parula, colormap
            if ~nargin
                numRows = 66;
            end
            
           m = parula( numRows );
        end
    end
end
