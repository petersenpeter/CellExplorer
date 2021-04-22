function trackGoogleAnalytics(appName,appVersion,varargin)

p = inputParser;
addParameter(p,'metrics',[],@isstruct); % cell_metrics struct
addParameter(p,'session',[],@isstruct); % session metadata struct
parse(p,varargin{:})
% metrics = p.Results.metrics;
% session = p.Results.session;

try
    trackingID = "UA-166238697-1"; % CellExplorer google analytics tracking ID
    hostname = "https://cellexplorer.org";
    tracker = mga.Tracker(trackingID, hostname);
    visitor = mga.Visitor('AppVersion', string(num2str(appVersion)));
    appName = string(['/',appName,'.app']);
    page1 = mga.hit.Pageview(appName);
    
    tracker.track(visitor, page1);
end
