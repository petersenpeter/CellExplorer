classdef RowSection < handle
    %ROWSECTION Content-sized classic controls, arranged in reusable rows.
    % Add/remove/hide rows without changing the parent section or scroll height.
    properties (SetAccess=private)
        Panel
        Body
        PreferredHeight = 1
    end
    properties (Access=private)
        Rows = struct('id',{},'grid',{},'controls',{},'label',{},'visible',{})
        Busy = false
        FontSize = 10
    end
    events
        HeightChanged
    end
    methods
        function obj=RowSection(parent,title,fontSize)
            if nargin>=3, obj.FontSize=fontSize; end
            obj.Panel=uix.BoxPanel('Parent',parent,'Title',title,'FontSize',obj.FontSize, ...
                'Padding',0,'MinimizeFcn',@(~,~) obj.refresh());
            obj.Body=uix.VBox('Parent',obj.Panel,'Padding',4,'Spacing',0);
            obj.Panel.SizeChangedFcn=@(~,~) obj.refresh();
            obj.Panel.DeleteFcn=@(~,~) delete(obj);
            obj.refresh();
        end
        function control=addField(obj,id,label,style,varargin)
            controls=obj.addRow(id,{'Style','text','String',label,'HorizontalAlignment','left'}, ...
                [{'Style',style},varargin]);
            control=controls(2);
        end
        function controls=addRow(obj,id,leftProperties,rightProperties)
            id=char(id);
            if any(strcmp({obj.Rows.id},id))
                error('ce:ui:DuplicateRow','Row ID already exists: %s.',id);
            end
            obj.Busy=true; mutation=onCleanup(@() obj.unlock()); %#ok<NASGU>
            grid=uix.Grid('Parent',obj.Body,'Padding',2,'Spacing',4);
            try
                left=uicontrol('Parent',grid,'FontUnits','points','FontSize',obj.FontSize,leftProperties{:});
                right=uicontrol('Parent',grid,'FontUnits','points','FontSize',obj.FontSize,rightProperties{:});
            catch exception
                delete(grid); rethrow(exception);
            end
            controls=[left right];
            label=''; if strcmp(left.Style,'text'), label=left.String; end
            obj.Rows(end+1)=struct('id',id,'grid',grid,'controls',controls,'label',{label},'visible',true);
            clear mutation
            obj.refresh();
        end
        function setRowVisible(obj,id,visible)
            validateattributes(visible,{'logical'},{'scalar'});
            index=obj.rowIndex(id); obj.Rows(index).visible=visible;
            obj.Rows(index).grid.Visible=onOff(visible);
            obj.refresh();
        end
        function removeRow(obj,id)
            index=obj.rowIndex(id); grid=obj.Rows(index).grid;
            obj.Busy=true; mutation=onCleanup(@() obj.unlock()); %#ok<NASGU>
            obj.Rows(index)=[]; delete(grid);
            clear mutation
            obj.refresh();
        end
        function setCollapsed(obj,collapsed)
            validateattributes(collapsed,{'logical'},{'scalar'});
            obj.Panel.Minimized=collapsed; obj.refresh();
        end
        function setFontSize(obj,value)
            validateattributes(value,{'numeric'},{'scalar','finite','positive'});
            obj.FontSize=value; obj.Panel.FontSize=value;
            for row=obj.Rows, set(row.controls,'FontSize',value); end
            obj.refresh();
        end
        function refresh(obj)
            if obj.Busy || ~isgraphics(obj.Panel) || ~isgraphics(obj.Body), return; end
            obj.Busy=true; cleanup=onCleanup(@() obj.unlock()); %#ok<NASGU>
            bounds=getpixelposition(obj.Panel);
            width=max(1,bounds(3)-2*obj.Panel.BorderWidth-2*obj.Body.Padding-4);
            heights=zeros(1,numel(obj.Rows));
            for index=1:numel(obj.Rows)
                row=obj.Rows(index);
                if ~row.visible, continue; end
                controls=row.controls;
                if ~isempty(row.label), controls(1).String=row.label; end
                leftWidth=controls(1).Extent(3)+8;
                if strcmp(controls(1).Style,'checkbox'), leftWidth=leftWidth+20; end
                rightWidth=80;
                if strcmp(controls(2).Style,'checkbox'), rightWidth=controls(2).Extent(3)+28; end
                if strcmp(controls(2).Style,'popupmenu'), rightWidth=110; end
                height=max(26,ceil(max([controls.FontSize])*1.7+8));
                if leftWidth+rightWidth+row.grid.Spacing <= width
                    row.grid.Widths=[leftWidth -1]; row.grid.Heights=height;
                    heights(index)=height+2*row.grid.Padding;
                else
                    labelHeight=height;
                    if ~isempty(row.label)
                        wrapLabel(controls(1),row.label,width);
                        labelHeight=max(height,controls(1).Extent(4)+4);
                    end
                    row.grid.Widths=-1; row.grid.Heights=[labelHeight height];
                    heights(index)=labelHeight+height+row.grid.Spacing+2*row.grid.Padding;
                end
            end
            obj.Body.Heights=heights;
            titleHeight=obj.Panel.TitleHeight+2*obj.Panel.BorderWidth;
            preferred=titleHeight;
            if ~obj.Panel.Minimized, preferred=preferred+sum(heights)+2*obj.Body.Padding; end
            if preferred~=obj.PreferredHeight
                obj.PreferredHeight=preferred;
                notify(obj,'HeightChanged');
            end
        end
        function delete(obj)
            if isgraphics(obj.Panel)
                obj.Panel.DeleteFcn=[]; obj.Panel.SizeChangedFcn=[]; obj.Panel.MinimizeFcn=[];
                delete(obj.Panel);
            end
        end
    end
    methods (Access=private)
        function index=rowIndex(obj,id)
            index=find(strcmp({obj.Rows.id},char(id)),1);
            if isempty(index), error('ce:ui:UnknownRow','Unknown row ID: %s.',char(id)); end
        end
        function unlock(obj)
            obj.Busy=false;
        end
    end
end
function value=onOff(flag)
if flag, value='on'; else, value='off'; end
end
function wrapLabel(control,label,width)
% Measure candidate lines using the actual font, without additional controls.
if iscell(label), label=strjoin(label,' '); end
words=regexp(char(label),'\s+','split'); lines={}; line='';
for index=1:numel(words)
    candidate=strtrim([line,' ',words{index}]); control.String=candidate;
    if control.Extent(3)>width && ~isempty(line)
        lines{end+1}=line; line=words{index}; %#ok<AGROW>
    else
        line=candidate;
    end
end
control.String=[lines,{line}];
end
