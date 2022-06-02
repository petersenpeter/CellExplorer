function content = content_dialog(content)
    % This generates a dialog that presents a variable set of inputs to functions. 
    % Please see content_dialog_example for an example of how to use this function.
    % 
    % Input: 
    %    content: a struct with fields:
    %       .title: dialog title
    %       .columns: 1 or 2 columns of fields
    %       .field_names: name of the variables/fields
    %       .field_title: Titles shown above the fields
    %       .field_style: popupmenu, edit, checkbox, radiobutton, togglebutton, listbox
    %       .field_default: default values
    %       .format: char, numeric, logical (boolean)
    %       .field_options: options for popupmenus
    %       .field_required: field required?
    %       .continue: how the dialog was closed
    %
    % Output:
    %   content.output : cell-arraay field with values
    %
    % Part of CellExplorer
    % by Peter Petersen
    
    content.continue = false;
    UI = {};
    if content.columns == 1
        width_dialog = 330;
        width_fields = 300;
        width_buttons = 150;
        height_dialog = numel(content.field_names)*50+50;
    else
        width_dialog = 530;
        width_fields = 250;
        width_buttons = 250;
        height_dialog = ceil(numel(content.field_names)/2)*50+50;
    end
    UI.dialog = dialog('Position', [300, 330, width_dialog, height_dialog],'Name',content.title,'WindowStyle','modal','visible','off');
    
    movegui(UI.dialog,'center'); set(UI.dialog,'visible','on');
    
    generate_dialog
    
    uiwait(UI.dialog)
    
    function generate_dialog
        
        % Filling in dialog
        vertical_offset = height_dialog;
        for i = 1:numel(content.field_names)
            
            % Determining the horizontal offset
            if rem(i,2) == 1 | content.columns == 1
                horizontal_offset = 10;
                % Determining vertical offset
                vertical_offset = vertical_offset-50;
            else
                horizontal_offset = width_fields+20;
            end            
            
            if content.field_required(i)
                string_title = [content.field_title{i},' *'];
            else
                string_title = content.field_title{i};
            end
            
            if any(strcmp(content.field_style{i},{'edit','popupmenu'}))
                titles1.(content.field_names{i}) = uicontrol('Parent',UI.dialog,'Style', 'text', 'String', string_title, 'Position', [horizontal_offset, vertical_offset+25, width_fields, 20],'HorizontalAlignment','left');
            end
            
            if strcmp(content.field_style{i},'edit')
                UI.fields.(content.field_names{i}) = uicontrol('Parent',UI.dialog,'Style', 'edit','Tag',content.field_names{i}, 'String', content.field_default{i}, 'Position', [horizontal_offset, vertical_offset, width_fields, 25],'HorizontalAlignment','left');

            elseif strcmp(content.field_style{i},'checkbox')
                UI.fields.(content.field_names{i}) = uicontrol('Parent',UI.dialog,'Style', 'checkbox','Tag',content.field_names{i}, 'String', content.field_title{i}, 'Position', [horizontal_offset, vertical_offset, width_fields, 25],'HorizontalAlignment','left','value',content.field_default{i});
                
            elseif strcmp(content.field_style{i},'popupmenu')
                value1 = find(strcmp(content.field_options{i},content.field_default{i}));
                if isempty(value1)
                    value1 = 1;
                end
                UI.fields.(content.field_names{i}) = uicontrol('Parent',UI.dialog,'Style', 'popupmenu','Tag',content.field_names{i}, 'String', content.field_options{i}, 'Position', [horizontal_offset, vertical_offset, width_fields, 25],'HorizontalAlignment','left','value',value1);
             
            end
            
        end

        uicontrol('Parent',UI.dialog,'Style','pushbutton','Position',[10, 10, width_buttons, 30],'String','OK','Callback',@close_dialog);
        uicontrol('Parent',UI.dialog,'Style','pushbutton','Position',[width_buttons+20, 10, width_buttons, 30],'String','Cancel','Callback',@cancel_dialog);
    end
    
    function close_dialog(~,~)
        for i = 1:numel(content.field_names)
            if content.field_required(i) && isempty(UI.fields.(content.field_names{i}).String)
                titles1.(content.field_names{i}).ForegroundColor = [1 0 0];
                titles1.(content.field_names{i}).FontWeight = 'bold';
                helpdlg(['Please fill out the required field: ' content.field_title{i}],'Error');
                return
            end
            
            if strcmp(content.field_style{i},'popupmenu') && strcmp(content.format{i},'char')
                content.output{i} = UI.fields.(content.field_names{i}).String{UI.fields.(content.field_names{i}).Value};
                
            elseif strcmp(content.field_style{i},'popupmenu') && strcmp(content.format{i},'numeric')
                content.output{i} = str2num(UI.fields.(content.field_names{i}).String{UI.fields.(content.field_names{i}).Value});
                
            elseif strcmp(content.field_style{i},'checkbox')
                if UI.fields.(content.field_names{i}).Value==1
                    content.output{i} = true;
                else
                    content.output{i} = false;
                end
                
            elseif strcmp(content.field_style{i},'edit') && strcmp(content.format{i},'char')
                 content.output{i} = UI.fields.(content.field_names{i}).String;
                 
            elseif strcmp(content.field_style{i},'edit') && strcmp(content.format{i},'numeric')
                    content.output{i} = str2num(UI.fields.(content.field_names{i}).String);

            end
        end
        content.continue = true;
        delete(UI.dialog);
    end
        
    function cancel_dialog(~,~)
        content.continue = false;
        delete(UI.dialog);
    end
end