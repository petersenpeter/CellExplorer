% Getting cell type groups (for coloring notes)
cellTypes = unique(cell_metrics.putativeCellType,'stable');
clusClas = ones(1,length(cell_metrics.putativeCellType));
for i = 1:length(cellTypes)
    clusClas(strcmp(cell_metrics.putativeCellType,cellTypes{i}))=i;
end

% Getting connection pairs and cells with connections
putativeConnections = cell_metrics.putativeConnections.excitatory;
putativeConnections_inh = cell_metrics.putativeConnections.inhibitory;
[cellSubset,~,pairsSubset] = unique([putativeConnections;putativeConnections_inh]);
pairsSubset = reshape(pairsSubset,size([putativeConnections;putativeConnections_inh]));

% Generating connectivity matrix (A)
A = zeros(length(cellSubset),length(cellSubset));
for i = 1:size(putativeConnections,1)
    A(pairsSubset(i,1),pairsSubset(i,2)) = 1;
end
for i = size(putativeConnections,1)+1:size(pairsSubset,1)
    A(pairsSubset(i,1),pairsSubset(i,2)) = 2;
end

% Plotting connectivity matrix
figure, subplot(1,2,1)
imagesc(A), title('Connectivity matrix')

% Generating connectivity graph (only for subset of cells with connections)
connectivityGraph = digraph(A);

% Plotting connectivity graph
subplot(1,2,2)
connectivityGraph_plot = plot(connectivityGraph,'Layout','force','Iterations',15,'MarkerSize',3,'EdgeCData',connectivityGraph.Edges.Weight,'HitTest','off','EdgeColor',[0.2 0.2 0.2],'NodeLabel',{});
title('Connectivity graph')

% Coloring nodes by cell types
classes2plotSubset = 1:numel(cellTypes);
colors = [[.5,.5,.5];[.8,.2,.2];[.2,.2,.8];[0.2,0.8,0.8];[0.8,0.2,0.8];[.2,.8,.2]];
for k = 1:length(classes2plotSubset)
    idx3 = find(clusClas(cellSubset)==classes2plotSubset(k));
    if ~isempty(find(clusClas(cellSubset)==classes2plotSubset(k)))
        highlight(connectivityGraph_plot,idx3,'NodeColor',colors(k,:))
    end
end
