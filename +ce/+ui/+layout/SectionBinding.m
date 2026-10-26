classdef SectionBinding < handle
    %SECTIONBINDING Coalesce measured-height updates outside parent redraws.
    % Uix lays out synchronously. Updating an ancestor inside its child resize
    % callback can leave stale sibling positions; defer that feedback once.
    properties (Access=private)
        Section
        Stack
        Scroller
        Timer
        ChangedListener
        DestroyListener
        Applying = false
        Pending = false
        Deleting = false
    end
    methods
        function obj=SectionBinding(section,stack,scroller)
            obj.Section=section; obj.Stack=stack; obj.Scroller=scroller;
            obj.Timer=timer('Name','CellExplorer section layout','ExecutionMode','singleShot', ...
                'StartDelay',.02,'TimerFcn',@(~,~) obj.flush(), ...
                'StopFcn',@(~,~) obj.schedule());
            obj.ChangedListener=addlistener(section,'HeightChanged',@(~,~) obj.request());
            obj.DestroyListener=addlistener(section.Panel,'ObjectBeingDestroyed',@(~,~) delete(obj));
            obj.flush();
        end
        function flush(obj)
            % Explicit settling is also useful before captures or geometry checks.
            if ~isvalid(obj) || obj.Applying || obj.Deleting, return; end
            obj.Applying=true; cleanup=onCleanup(@() obj.unlock()); %#ok<NASGU>
            for pass=1:8
                obj.Pending=false;
                if ~isvalid(obj) || obj.Deleting || ~isvalid(obj.Section) || ...
                        ~isgraphics(obj.Stack) || ~isgraphics(obj.Scroller) || ~isgraphics(obj.Section.Panel), return; end
                % The figure/scroller may be deleting internal graphics before
                % the section's destruction listener is reached.
                parent=obj.Scroller;
                while isgraphics(parent) && isprop(parent,'BeingDeleted')
                    if strcmp(parent.BeingDeleted,'on'), return; end
                    parent=parent.Parent;
                end
                if strcmp(obj.Stack.BeingDeleted,'on'), return; end
                index=find(obj.Stack.Contents==obj.Section.Panel,1);
                if isempty(index), return; end
                heights=obj.Stack.Heights; minimums=obj.Stack.MinimumHeights;
                % A graphics constructor can dispatch timers while the child list
                % and container size vectors are temporarily out of sync.
                count=numel(obj.Stack.Contents);
                if numel(heights)~=count || numel(minimums)~=count
                    obj.Pending=true; return
                end
                heights(index)=obj.Section.PreferredHeight; minimums(index)=obj.Section.PreferredHeight;
                obj.Stack.Heights=heights; obj.Stack.MinimumHeights=minimums;
                ce.ui.layout.fitScrollingStack(obj.Stack,obj.Scroller);
                if ~obj.Pending, break; end
            end
        end
        function delete(obj)
            if obj.Deleting, return; end
            obj.Deleting=true;
            if ~isempty(obj.Timer) && isvalid(obj.Timer)
                obj.Timer.StopFcn=[]; stop(obj.Timer); delete(obj.Timer);
            end
            delete(obj.ChangedListener); delete(obj.DestroyListener);
        end
    end
    methods (Access=private)
        function request(obj)
            if ~isvalid(obj) || obj.Deleting, return; end
            obj.Pending=true; obj.schedule();
        end
        function schedule(obj)
            if isvalid(obj) && ~obj.Deleting && ~obj.Applying && obj.Pending && isvalid(obj.Timer) && strcmp(obj.Timer.Running,'off')
                start(obj.Timer);
            end
        end
        function unlock(obj)
            if ~isvalid(obj) || obj.Deleting, return; end
            obj.Applying=false; obj.schedule();
        end
    end
end
