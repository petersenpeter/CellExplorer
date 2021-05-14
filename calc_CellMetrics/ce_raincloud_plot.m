% raincloud_plot - plots a combination of half-violin, boxplot,  and raw
% datapoints (1d scatter).
% Use as h = raincloud_plot(X), where X is a data vector is a cell array of handles for the various figure parts.
% Seee below for optional inputs.
% Based on https://micahallen.org/2018/03/15/introducing-raincloud-plots/
% Inspired by https://m.xkcd.com/1967/
% v1 - Written by Tom Marshall. www.tomrmarshall.com
% v2 - Updated inputs to be more flexible - Micah Allen 12/08/2018
%
% Thanks to Jacob Bellmund for some improvements
%
% Modified by Peter Petersen, new output, removing nan and inf values, and turned off HitTest (renamed to ce_raincloud_plot)

function drops_pos = ce_raincloud_plot(X, varargin)
    
    % ---------------------------- INPUT ----------------------------
    %
    % X - vector of data to be plotted, required.
    %
    % --------------------- OPTIONAL ARGUMENTS ----------------------
    %
    % color             - color vector for rainclouds (default gray, i.e. = [.5 .5 .5])
    % band_width        - band_width of smoothing kernel (default = 1)
    % density_type      - choice of density algo ('ks' or 'rath'). Default = 'ks'
    % box_on            - logical to turn box plots on/off (default = 0)
    % box_dodge         - logical to turn on/off box plot dodging (default = 0)
    % box_dodge_amount  - mutiplicative value to increase dodge amount (default = 0)
    % alpha             - scalar positive value to increase cloud alpha (defalut = 1)
    % dot_dodge_amount  - scalar value to increase dot dodge amounts (defalut =0.6)
    % box_col_match     - logical to set it so that boxes match the colour of clouds (default = 0)
    % line_width        - scalar value to set global line width (default = 2)
    % lwr_bnd           - mutiplicative value to increase spacing at bottom of plot(default = 1)
    % bxcl              - color of box outline
    % bxfacecl          - color of box face
    %
    % ---------------------------- OUTPUT ----------------------------
    % h - figure handle to change more stuff
    % u - parameter from kernel density estimate
    %
    % ------------------------ EXAMPLE USAGE -------------------------
    %
    % h = raincloud('X', myData, 'box_on', 1, 'color', [0.5 0.5 0.5])
    
    %% check all the inputs and if they do not exist then revert to default settings
    % input parsing settings
    p = inputParser;
    p.CaseSensitive = true;
    p.Parameters;
    p.Results;
    p.KeepUnmatched = true;
    validScalarPosNum = @(x) isnumeric(x) && isscalar(x) && (x > 0);
    
    % set the desired and optional input arguments
    addRequired(p, 'X', @isnumeric);
    addOptional(p, 'color', [0.5 0.5 0.5], @isnumeric)
    addOptional(p, 'band_width', [])
    addOptional(p, 'density_type', 'ks', @ischar)
    addOptional(p, 'box_on', 0, @isnumeric)
    addOptional(p, 'box_dodge', 0, @isnumeric)
    addOptional(p, 'box_dodge_amount', 0, @isnumeric)
    addOptional(p, 'alpha', 1, validScalarPosNum)
    addOptional(p, 'dot_dodge_amount', 0.4, @isnumeric)
    addOptional(p, 'box_col_match', 0, @isnumeric)
    addOptional(p, 'line_width', 1, validScalarPosNum)
    addOptional(p, 'lwr_bnd', 1, @isnumeric)
    addOptional(p, 'bxcl', [0 0 0], @isnumeric)
    addOptional(p, 'bxfacecl', [1 1 1], @isnumeric)
    addOptional(p, 'cloud_edge_col', [0 0 0], @isnumeric)
    addOptional(p, 'log_axis', 0, @isnumeric)
    addOptional(p, 'randomNumbers', [], @isnumeric)
    addOptional(p, 'markerSize', 14, @isnumeric)
    addOptional(p, 'normalization', 'Peak', @ischar)
    addOptional(p, 'norm_value', 1, @isnumeric)
    addOptional(p, 'scatter_on', 1, @isnumeric)
    addOptional(p, 'ylim', get(gca, 'YLim'), @isnumeric)
    % parse the input
    parse(p,X,varargin{:});
    
    % then set/get all the inputs out of this structure
    X                   = p.Results.X;
    color               = p.Results.color;
    density_type        = p.Results.density_type;
    box_on              = p.Results.box_on;
    box_dodge           = p.Results.box_dodge;
    box_dodge_amount    = p.Results.box_dodge_amount;
    alpha               = p.Results.alpha;
    dot_dodge_amount    = p.Results.dot_dodge_amount;
    box_col_match       = p.Results.box_col_match;
    line_width          = p.Results.line_width;
    lwr_bnd             = p.Results.lwr_bnd;
    bxcl                = p.Results.bxcl;
    bxfacecl            = p.Results.bxfacecl;
    cloud_edge_col      = p.Results.cloud_edge_col;
    band_width          = p.Results.band_width;
    log_axis            = p.Results.log_axis;
    randomNumbers       = p.Results.randomNumbers;
    markerSize          = p.Results.markerSize;
    normalization       = p.Results.normalization;
    norm_value          = p.Results.norm_value;
    scatter_on          = p.Results.scatter_on;
    yl                  = p.Results.ylim;
    
    % calculate kernel density
    X = X(~isnan(X) & ~isinf(X));
    drops_pos = [];
    
    if isempty(X)
        return
    end
    
    if log_axis
        X = X(X>0);
        if all(isnan(X))
            return
        end
        [f, Xi, ~] = ksdensity(log10(X), 'bandwidth', band_width,'Function','pdf');
        Xi = 10.^Xi;
    else
        [f, Xi, ~] = ksdensity(X, 'bandwidth', band_width,'Function','pdf');
    end
    
    % density plot
    if strcmp(normalization,'Peak')
        f = f/max(f);
    elseif strcmp(normalization,'Count')
        f = f/sum(f)*norm_value;
    else % Probability
%         f = f*length(Xi)/100;
        f = f/sum(f);
    end
    h{1} = area(Xi, f, 'FaceColor', color, 'EdgeColor', cloud_edge_col, 'LineWidth', line_width, 'FaceAlpha', alpha); hold on
    % make some space under the density plot for the boxplot and raindrops
%     yl = get(gca, 'YLim');
%     set(gca, 'YLim', [-yl(2)*lwr_bnd yl(2)]);
    
    % width of boxplot
    wdth = yl(2) * 0.25;
    wdth_box = yl(2) * 0.05;
    if isempty(randomNumbers)
        randomNumbers = rand(1,length(X));
    end
    jit = (randomNumbers(1:length(X)) - 0.5) * wdth;
    
    % info for making boxplot
    quartiles   = quantile(X, [0.25 0.75 0.5]);
    iqr         = quartiles(2) - quartiles(1);
    Xs          = sort(X);
    if unique(Xs) == 0
        whiskers(1) = 0;
        whiskers(2) = 0;
    else
        if ~isempty(min(Xs(Xs > (quartiles(1) - (1.5 * iqr)))))
            whiskers(1) = min(Xs(Xs > (quartiles(1) - (1.5 * iqr))));
        else
            whiskers(1) = 0;
        end
        if ~isempty(max(Xs(Xs < (quartiles(2) + (1.5 * iqr)))))
            whiskers(2) = max(Xs(Xs < (quartiles(2) + (1.5 * iqr))));
        else
            whiskers(2) = 0;
        end
    end
    Y  = [quartiles whiskers];
    
    % raindrops
    if box_dodge
        drops_pos = (jit * 0.6) - yl(2) * dot_dodge_amount;
    else
        drops_pos = jit - yl(2) / 2;
    end
%      h{2} = scatter(X, drops_pos,'HitTest','off','SizeData',markerSize,'MarkerFaceColor',color,'MarkerEdgeColor','none');
    if scatter_on
        h{2} = line(X, drops_pos,'HitTest','off','markersize',markerSize-5,'MarkerFaceColor',color,'LineStyle','none','Marker','.','color',color);
    end
    if box_on
        if box_col_match
            bxcl = color;
        end
        box_pos = [Y(1) ((-yl(2) * box_dodge_amount) - (wdth_box * 0.3)) Y(2) - Y(1) (wdth_box * 0.6)];
        % whiskers
        h{5} = line([Y(2) Y(5)], [(-yl(2) * box_dodge_amount) (-yl(2) * box_dodge_amount)], 'col', bxcl, 'LineWidth', line_width,'HitTest','off');
        % 'box' of 'boxplot'
        h{3} = rectangle('Position', box_pos,'HitTest','off', 'EdgeColor', bxcl, 'LineWidth', line_width);
        % mean line
        h{4} = line([Y(3) Y(3)], [((-yl(2) * box_dodge_amount) - (wdth_box * 0.3)) ((-yl(2) * box_dodge_amount) + (wdth_box * 0.3))], 'col', bxcl, 'LineWidth', line_width,'HitTest','off');
        
    end
