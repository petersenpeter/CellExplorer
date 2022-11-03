function output = dialog_general(varargin)
    output = {};
    p = inputParser;
    addParameter(p,'dialog_title','',@isstr);
    addParameter(p,'dimensions',[300, 400],@isnumeric);
    addParameter(p,'padding',10,@isnumeric);
    addParameter(p,'list_options',{''},@iscellstr);
    addParameter(p,'list_value',1,@isnumeric);
    addParameter(p,'list_title','',@isstr);
    addParameter(p,'list_max',1,@isnumeric);
    
    addParameter(p,'text1_value','',@isstr);
    addParameter(p,'text1_title','',@isstr);
    parse(p,varargin{:});
    
    parameters = p.Results;
    
    % Layout values
    field_width = parameters.dimensions(1)-2*parameters.padding;
    field_width_half = (parameters.dimensions(1)-3*parameters.padding)/2;
    
    general_dialog = dialog('Position', [0, 0, parameters.dimensions(1), parameters.dimensions(2)],'Name',parameters.dialog_title,'visible','off'); movegui(general_dialog,'center'), set(general_dialog,'visible','on')
    
    % Text field
    uicontrol('Parent',general_dialog,'Style', 'text', 'String', parameters.text1_title, 'Position', [parameters.padding, 375, field_width, 20],'HorizontalAlignment','left');
    text1_uicontrol = uicontrol('Parent',general_dialog,'Style', 'Edit', 'String', parameters.text1_value, 'Position', [parameters.padding, 350, field_width, 25],'HorizontalAlignment','left');
    
    % List field
    uicontrol('Parent',general_dialog,'Style', 'text', 'String', parameters.list_title, 'Position', [parameters.padding, 320, field_width, 20],'HorizontalAlignment','left');
    list_uicontrol = uicontrol('Parent',general_dialog,'Style', 'ListBox', 'String', parameters.list_options, 'Position', [parameters.padding, 50, field_width, 270],'Value',parameters.list_value,'Max',parameters.list_max,'Min',1);
    
    % Buttons
    uicontrol('Parent',general_dialog,'Style','pushbutton','Position',[parameters.padding, parameters.padding, field_width_half, 30],'String','OK','Callback',@(src,evnt)close_dialog);
    uicontrol('Parent',general_dialog,'Style','pushbutton','Position',[2*parameters.padding+field_width_half, parameters.padding, field_width_half, 30],'String','Cancel','Callback',@(src,evnt)cancel_dialog);
    
    uicontrol(text1_uicontrol)
    uiwait(general_dialog);
    
    function close_dialog
        output.list_value = list_uicontrol.Value;
        output.text1_value = text1_uicontrol.String;
        delete(general_dialog);        
    end
    
    function cancel_dialog
        % Closes dialog
        delete(general_dialog);
    end
end
