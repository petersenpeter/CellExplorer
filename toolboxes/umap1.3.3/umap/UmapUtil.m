%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%
classdef UmapUtil < handle
    methods(Static)
        function [x,y,z]=Labels(inputDims, outputDims, ax)
            dimInfo=sprintf('  %dD\\rightarrow%dD', ...
                inputDims, outputDims);
            x=['UMAP-X' dimInfo];
            y=['UMAP-Y' dimInfo];
            if outputDims>2
                z=['UMAP-Z' dimInfo];
            end
            if nargin>2
                xlabel(ax, x);
                ylabel(ax, y);
                if outputDims>2
                    zlabel(ax, z);
                end                
            end
        end
    end
end