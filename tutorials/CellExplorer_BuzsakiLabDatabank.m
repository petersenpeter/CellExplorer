%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% Tutorial for running CellExplorer from the Buzsaki lab database
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

%  1. Define your credentials and local repositories by editing the two files:
edit db_credentials.m
edit db_local_repositories.m

%% 2. Define sessionName/basename of a dataset existing in the database. The dataset should at minimum consist of a sessionName.dat, a sessionName.xml and spike sorted data.
sessionName = 'Rat08-20130708';

%% 3. Run the cell metrics pipeline using the session name as input
cell_metrics = ProcessCellMetrics('sessionName', sessionName);

%% 4. Visualize the cell metrics in CellExplorer
cell_metrics = CellExplorer('metrics',cell_metrics);
