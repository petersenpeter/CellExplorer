function subsetPlots = pieChart(cell_metrics,UI,ii,col)
    % INPUTS
    % cell_metrics      cell_metrics struct
    % UI                the struct with figure handles, settings and parameters
    % ii                index of the current cell
    % col               color of the current cell
    %
    % OUTPUT
    % subsetPlots       a struct with any extra single cell plots from synaptic partner cells
    %   .xaxis          x axis data (Nx1), where N is the number of samples 
    %   .yaxis          y axis data (NxM), where M is the number of cells
    %   .subset         list of cellIDs (Mx1)
    
    % By Peter Petersen
    % petersen.peter@gmail.com
    % Last updated 06-12-2020
    
    subsetPlots = [];
    
    b12 = nanUnique(UI.classes.plot(UI.params.subset));
    [cnt_unique, ~] = histc(UI.classes.plot(UI.params.subset),b12);
    pie_handle = pie(cnt_unique/sum(cnt_unique));
    patchHand = findobj(pie_handle, 'Type', 'Patch'); 
    % Set the color of all patches using the UI.classes.colors matrix
    set(patchHand, {'FaceColor'}, mat2cell(UI.classes.colors, ones(size(UI.classes.colors,1),1), 3),{'EdgeColor'}, mat2cell(UI.classes.colors, ones(size(UI.classes.colors,1),1), 3))
    title('Pie chart'), xlabel(' '), ylabel(' '), xlim([-1.3,1.3]), ylim([-1.3,1.3]) 
end