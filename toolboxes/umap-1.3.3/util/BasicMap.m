%   AUTHORSHIP
%   Primary Developer: Stephen Meehan <swmeehan@stanford.edu> 
%   Math Lead & Secondary Developer:  Connor Meehan <cgmeehan@alumni.caltech.edu>
%   Bioinformatics Lead:  Wayne Moore <wmoore@stanford.edu>
%   Provided by the Herzenberg Lab at Stanford University 
%   License: BSD 3 clause
%

% this wrapper around MatLab internal map is meant for 
% polymorphic function signature compatability with other
% classdef and JAVA class in CytoGenie AutoGate
classdef BasicMap < handle
    properties
        map;
        pu;
        parentCmpForPopup;
        propertyFile=[];
    end
    
    properties(SetAccess=private)
        appFolder;
        contentFolder;
        toolBarSize=0;
        toolBarFactor=0;
        highDef=false;
        supStart='<sup>';
        supEnd='</sup>';
        subStart='<sub>';
        subEnd='</sub>';
        smallStart='<small>';
        smallEnd='</small>';
        h3Start='<h3>';
        h3End='</h3>';
        h2Start='<h2>';
        h2End='</h2>';
        h1Start='<h1>';
        h1End='</h1>';
        whereMsgOrQuestion='center';
    end
    
    methods(Static)
        function this=Global(closeIfTrueOrMap)
            persistent singleton;
            if nargin>0 && islogical(closeIfTrueOrMap) && closeIfTrueOrMap
                clear singleton;
                singleton=[];
                disp('Resetting global BasicMap');
                this=[];
            else
                if nargin==1
                    try
                        priorMap=closeIfTrueOrMap;
                        %test method compatibility
                        priorMap.size
                        prop='IsBasicMap';
                        if ~priorMap.has(prop)
                            priorMap.set(prop, 'false')
                            priorMap.get(prop, 'true')
                            priorMap.remove(prop);
                        else
                            priorMap.get(prop, 'true')
                        end
                        singleton=priorMap;
                        this=singleton;
                        return;
                    catch ex
                        ex.getReport
                    end
                end
                if isempty(singleton) 
                    singleton=BasicMap;
                    singleton.highDef=Gui.hasPcHighDefinitionAProblem(2000, 2500, false);
                end     
                this=singleton;
            end
        end
        
        function path=Path
            path=BasicMap.Global.contentFolder;
        end
        
        function obj=SetHighDef(obj, hasHighDef)
            factor=0;
            NORMAL_FONT_SIZE=12;
            SMALL_FONT_SIZE=2;
            H3_FONT_SIZE=3;
            H2_FONT_SIZE=3.5;
            H1_FONT_SIZE=4;
            if hasHighDef
                obj.highDef=true;
                factor=javax.swing.UIManager.getFont('Label.font').getSize...
                    /NORMAL_FONT_SIZE;
            else
                if ismac
                    %factor=1.6;
                end
            end
            if factor>0
                obj.toolBarFactor=factor;
                obj.toolBarSize=floor(16*factor);
                smallSize=floor(SMALL_FONT_SIZE*factor);
                if ispc
                    smallSize=smallSize+1;
                end
                obj.smallStart=['<font size="' num2str(smallSize) '">'];
                obj.smallEnd='</font>';
                obj.subStart=obj.smallStart;
                obj.supStart=obj.smallStart;
                obj.subEnd=obj.smallEnd;
                obj.supEnd=obj.smallEnd;
                h1Size=floor(H1_FONT_SIZE *factor);
                if ispc
                    h1Size=h1Size+1;
                end
                obj.h1Start=['<center><font size="' num2str(h1Size) ...
                    '" color="blue"><b>'];
                obj.h1End='</b></font></center><br>';

                h2Size=floor(H2_FONT_SIZE *factor);
                if ispc
                    h2Size=h2Size+1;
                end
                obj.h2Start=['<center><font size="' num2str(h2Size) ...
                    '" color="blue"><b>'];
                obj.h2End='</b></font></center><br>';

                h3Size=floor(H3_FONT_SIZE *factor);
                if ispc
                    h3Size=h3Size+1;
                end
                obj.h3Start='<h1>';
                obj.h3End='</h1>';
            else
                obj.toolBarSize=0;
                obj.toolBarFactor=0;
                obj.highDef=false;
        
                obj.smallStart='<small>';
                obj.smallEnd='</small>';
                obj.h3Start='<h3>';
                obj.h3End='</h3>';
                obj.h2Start='<h2>';
                obj.h2End='</h2>';
                obj.h1Start='<h1>';
                obj.h1End='</h1>';

            end
        end
        
        
    end
    
    methods
        function this=BasicMap(keysOrFileName, values)
            if nargin==1 
                if ischar(keysOrFileName)
                    this.propertyFile=keysOrFileName;
                    this.load;
                    return;
                end
            end
            if nargin==2
                this.map=containers.Map(keysOrFileName, values);
            else
                this.map=containers.Map;
            end
            this.contentFolder=fileparts(mfilename('fullpath'));
            this.appFolder=this.contentFolder;
        end
        
        function cnt=size(this)
            cnt=this.map.length;
        end

        function reset(this)
            this.clear;
        end
        
        function clear(this)
            remove(this.map, this.map.keys);
        end

        function priorValue=remove(this, name)
            priorValue=this.get(name);
            remove(this.map, name);
        end
        
        function set(this, name, value)
            this.map(name)=value;
        end
        
        %for value char compatibility with outside map classes
        function setBoolean(this, name, isTrue)
            if isTrue
                isTrue='true';
            else
                isTrue='false';
            end
            this.map(name)=isTrue;
        end
        
        % for value char compatibility with outside map classes
        function setNumeric(this, name, num)
            this.map(name)=num2str(num);
        end

        function isTrue=is(this, name, defaultIsTrue)
            if this.map.isKey(name)
                value=this.map(name);
                if ischar(value)
                    value=strcmpi('yes', value);
                end 
                isTrue=value;
            else
                if nargin<3
                    isTrue=false;
                else
                    isTrue=defaultIsTrue;
                end
            end
        end
        
        function value=get(this, name, defaultValue)
            if this.map.isKey(name)
                value=this.map(name);
            else
                if nargin<3
                    value=[];
                else
                    value=defaultValue;
                end
            end
        end
        
        function closeToolTip(this)
        end
        
        function num=getNumeric(this, name, defaultNumber)
            num=this.get(name);
            if isempty(num)
                if nargin>2
                    num=defaultNumber;
                end
            elseif ischar(num)
                num=num2str(num);
            end
        end
        
        function ok=has(this, name)
            ok=this.map.isKey(name);
        end
        
        function save(this, propertyFile)
            if nargin>1
                this.propertyFile=propertyFile;
            end
            if ~isempty(this.propertyFile)
                basicMap=this;
                save(this.propertyFile, 'basicMap');
            end
        end
         
        function load(this, propertyFile)
            if nargin>1
                this.propertyFile=propertyFile;
            end
            if ~isempty(this.propertyFile)
                load(this.propertyFile, 'basicMap');
                pl = properties(this);
                for k = 1:length(pl)
                    if isprop(basicMap,pl{k})
                        this.(pl{k}) = basicMap.(pl{k});
                    end
                end
          
            end
        end
         
    end
end