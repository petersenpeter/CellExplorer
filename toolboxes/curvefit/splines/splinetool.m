function splinetool( varargin )
%SPLINETOOL   Experiment Spline Approximation Methods
%
%   SPLINETOOL prompts you for some data sites and data values to fit and
%   lets you do this in various ways.
%   One of the choices is to provide your own data, in which case both
%   the sites and values can be expressions that evaluate to vectors required
%   to be of the same length.
%   You can also specify the values by providing the name of a function whose
%   values at the sites are to be used as data values.
%   You can also provide the name of a function (like 'titanium') whose
%   two-argument output provides numerical values for sites and values.
%   In any case, there must be at least two distinct sites.
%   The other choices provide specific sample sites and values to illustrate
%   various aspects of the GUI.
%
%   SPLINETOOL(X,Y) uses the input data sites X and data values Y, and these
%   must be numerical vectors of the same length > 1. The data sites need not
%   be distinct nor ordered, but there must be at least two distinct sites.
%
%   Example:
%      x = linspace(1,pi,101); y = cos(x)+(rand(size(x))-.5)/10;
%      splinetool(x,y)
%   might start an interesting experimentation with noisy data.
%
%   See also CSAPI, CSAPS, SPAPS, SPAP2, SPAPI.

%   Copyright 1987-2015 The MathWorks, Inc.

if ~nargin || ~ischar( varargin{1} )
    iStartSplineTool( varargin{:} )
    
else
    action = varargin{1};
    
    hand = get(gcbf,'UserData');
    if isstruct(hand) && isfield(hand,'currentline')
        % make available, for use with changes
        hc = hand.currentline;
    end
    
    switch action
        case 'add_item'
            iDoAddItem(hand,hc);
        case 'align'
            iDoAlign(hand);
        case 'axesclick'
            iDoAxesClick(hand);
        case 'change_name'
            iDoChangeName(hand,hc);
        case 'change_order'
            iDoChangeOrder(hand,hc);
        case {'close','exit','finish','quit'}
            iDoTerminate();
        case 'closefile'
            iDoDeleteSplinetool()
        case 'data_etc'
            if nargin>1,
                hand = varargin{2};
            end
            iDoDataEtcetera(hand);
        case 'del'
            iDoDeleteSpline(hand);
        case 'del_item'
            iDoDeleteItem(hand,hc);
        case 'export_data'
            iDoExportData(hand);
        case 'export_spline'
            iDoExportSpline(hand);
        case 'ginputmove'
            iDoGraphicalInputMove(hand);
        case 'ginputdone'
            iDoGraphicalInputDone();
        case 'help'
            iDoHelp( varargin{2} );
        case 'highlightb'
            iMarkBreak(hand)
        case 'highlightw'
            iDoMarkWeight(hand);
        case 'highlightxy'
            iMarkDataPoint(hand)
        case 'increment'
            iDoIncrement(hand);
        case 'labels'
            iResetLabels(hand,[]);
        case 'make_current'
            iDoMakeCurrent(hand);
        case 'method'
            iSetupMethod(hand)
        case 'move_item'
            iDoMoveItem(hand);
        case 'new'
            iNewSpline(hand);
        case 'newknt'
            get_approx(hand)
        case 'parameters'
            parameters(hand)
        case 'pieces'
            get_approx(hand)
        case 'pm'
            iDoPlusMinus(hand);
        case 'print_graph'
            iDoPrintGraph(hand);
        case 'rep'
            iDoDuplicateSpline(hand,hc);
        case 'rep_knot'
            iDoDuplicateKnot(hand,hc);
        case 'restart'
            iDoRestart();
        case 'save2mfile'
            iDoWriteMatlabFile(hand,hc);
        case 'startcont'
            iContinueStartup(hand, varargin{2} );
        case 'startfinish'
            iDoFinalize( varargin{2} );
        case 'toggle_ends'
            iDoToggleEnds( hand, varargin{2});
        case 'toggle_show'
            iDoToggleShowSpline(hand);
        case 'tool'
            iDoToggleTool(hand);
        case 'undo'
            iDoUndo(hand);
        case 'view'
            iDoViewLowerPlot(hand);
        otherwise
            iDoBadInputErrorDialog();
    end % switch action
end
end  % splinetool

function index = iAddCommentedChange( hc, code, comment )
% iAddCommentedChange   Add some code and comment to a cell array of changes.
%
% The comment should be a message.
string = [code, '%% ', getString( comment )];
index = addchange( hc, string );
end  % iAddCommentedChange

function index = iAppendCommentedChange( hc, code, comment )
% iAppendCommentedChange   Append code and comment to the last element of cell
% array of changes.
%
% The comment should be a message.
string = [code, '%% ', getString( comment )];
index = addchange( hc, string, 'concat' );
end  % iAppendCommentedChange

function [index,changes] = addchange(hc, string, ~)
%ADDCHANGE append the STRING to cell array of changes

changes = get(hc,'UserData');
if nargin>2
    changes{end} = overlong([changes{end},string]);
else
    changes{end+1} = overlong(string);
end
set(hc,'UserData',changes)
index = length(changes);
end  % addchange

function [name,handle] = add_to_list(hand,name)
%ADD_TO_LIST Add name to list of splines, marking it shown and current.
% If no name is given, take the next default one.

listud = get(hand.list_names,'UserData');
names = get_names(get(hand.list_names,'String'));
if isempty(names)
    listud.untitleds = 1;
end

if nargin<2  % make up a name
    while 1
        name = ['spline',num2str(listud.untitleds),'   '];
        if listud.untitleds>9
            name = name(1:10);
        end
        listud.untitleds = listud.untitleds+1;
        if isempty(findobj('Tag',name))
            break
        end
    end
else % make sure the name is new and is exactly 10 characters long
    name = full_name(name);
end

prefix = 'v || ';
names = [names;[prefix ,name]];
listud.length = listud.length+1;

% generate a new line, with its linestyle
styles = {'-';'--';':';'-.'};
nstyles = length(styles);
handle = line('XData',NaN, 'YData',NaN, ...
    'Parent',hand.Axes(1), ...
    'LineStyle', styles{nstyles-rem(listud.length,nstyles)}, ...
    'ButtonDownFcn', 'splinetool ''axesclick''', ...
    'Tag',name);
listud.handles = [listud.handles;handle];

% save the updated userdata listud:
set(hand.list_names,'String', {names}, ...
    'Value', listud.length, ...
    'UserData',listud);

%  ... and set the line as showing in the graph:
set(hand.ask_show,'Value',1);
set(hand.currentline,'Visible','on');
end  % add_to_list

function [xx,yy] = ask_for_add(hand)
%ASK_FOR_ADD

switch get(gcbo,'Tag')
    case 'add_item'
        [xx,yy] = ginput(hand);
    case 'mov_item'
        [xx,yy] = get(hand.Axes(1),'CurrentPoint');
end % switch get(gcbo,'Tag')

if nargin>0&&get(hand.dataline,'UserData')
    yy = given(xx,hand);
end
end  % ask_for_add

function [x,y,xname,yname,isf] = ask_for_data
%ASK_FOR_DATA
% will return negative ISF in case user hits Cancel

answer = inputdlg({getString(message('SPLINES:resources:dlg_InputData')), ...
    getString(message('SPLINES:resources:dlg_InputDataXLabel')), ...
    getString(message('SPLINES:resources:dlg_InputDataY')), ...
    getString(message('SPLINES:resources:dlg_InputDataYLabel'))},...
    getString(message('SPLINES:resources:dlgTitle_DataInput')), 1, ...
    {'linspace(0,2*pi,31)','','cos',''},'on');
if ~isempty(answer)&&~isempty(answer{1})
    xname = answer{1};
    yname = answer{3};
    % check out the answers. Lack of knowledge restricts me to merely check
    % whether (a) x is a function, in which case I expect it to return both
    % x and y.
    if any(0+xname<48) % looks like a formula
        x = evalin('base',xname);
    else
        a = evalin('base',['which(''',xname,''');']);
        if length(a)>1&&isequal(lower(a(end-1:end)),'.m')
            % this is the name of a file, let's hope it
            % supplies both x and y
            [x,y] = evalin('base',xname);
            xname = 'x';
            yname = 'y';
        else
            x = evalin('base',xname);
        end
    end
    
    isf = 0;
    if ~exist('y','var')
        if any(0+yname<48) % looks like a formula
            y = evalin('base',yname);
        else
            isf = get_isf(yname,x);
            switch isf
                case {1,2},
                    y = feval(yname,x);
                case 0,
                    y = evalin('base',yname);
                otherwise
                    error(message('SPLINES:SPLINETOOL:unsuitablefunction', yname));
                    
            end
        end %if any(0+yname<48) % looks like a formula
    end %if ~exist('y','var')
    
    % check that x is nondecreasing
    [x,y] = chckxy(x,y);
    
    if ~isempty(answer{2}),
        xname = answer{2};
    end
    if ~isf&&~isempty(answer{4}),
        yname = answer{4};
    end
else   % take default data, but with  isf < 0
    isf = -1;
    [x,y] = titanium;
    xname = getString(message('SPLINES:resources:Temperature'));
    yname = getString(message('SPLINES:resources:TitaniumProperty'));
end %if ~isempty(answer)
end  % ask_for_data

function change_weight(hand)
%CHANGE_WEIGHT

V = get(hand.params(1,5),'Value');
lineud = get(hand.nameline,'UserData');
output = iEvaluateEditField( hand.params(2,5), lineud.w(V) );
if ischar(output)
    return
else
    w = output;
end

negs = find(w<0);
if ~isempty(negs)
    ermsg = ...
        warndlg(getString(message('SPLINES:resources:dlg_NegativeWeights')), ...
        getString(message('SPLINES:resources:dlgTitle_NegativeWeights')),'modal');
    % In anticipation of the next error message, ...
    set(ermsg,'Position',get(ermsg,'Position')+[0,60,0,0])
    w(negs) = 0;
end

if length(w)>1
    items = min(length(w),length(lineud.w)+1-V);
    lineud.w(V-1+(1:items)) = reshape(w(1:items),1,items);
else
    lineud.w(V) = w;
    items = 1;
end

%check that there are still at least two positive weights
if length(find(lineud.w>0))<2
    warndlg(getString(message('SPLINES:resources:dlg_InvalidRoughnessWeight')), ...
        getString(message('SPLINES:resources:dlgTitle_TwoPositiveWeights')),'modal')
    return
end
lineud.wc(end+1) = addchange(hand.currentline, ...
    '%% then you changed some error weights');
lineud.wc(end+1) = addchange(hand.currentline, ...
    ['r=[',num2str(V-1+(1:items)),'];\n', ...
    'weights(r) = [',num2str(lineud.w(V-1+(1:items)),15),'];']);

set(hand.nameline,'UserData',lineud)
set(hand.params(1,5),'String',lineud.w(:));
set(hand.params(2,5),'String',lineud.w(V))

get_approx(hand)

end  % change_weight

function [x,y] = chckxy(x,y)
%CHCKXY check the given data

x = x(:).';
y = y(:).';
if length(x)~=length(y)
    error(message('SPLINES:SPLINETOOL:sitesdontmatchvalues', num2str( length( x ) ), num2str( length( y ) )));
end

nfins = find(sum(~isfinite([x;y])));
if ~isempty(nfins)
    x(nfins) = [];
    y(nfins) = [];
    temp = warndlg(...
        getString(message('SPLINES:resources:dlg_IgnoreNaNsOrInfs')), ...
        getString(message('SPLINES:resources:dlgTitle_ImportData')));
    waitfor(temp)
end

% make sure data are real:
if ~all(isreal(x))||~all(isreal(y))
    x = real(x);
    y = real(y);
    temp = warndlg(...
        getString(message('SPLINES:resources:dlg_IgnoreImaginaryPart')), ...
        getString(message('SPLINES:resources:dlgTitle_ImportData')));
    waitfor(temp)
end

% make sure data sites are nondecreasing:
dx = diff(x);
if any(dx<0),
    [x,index] = sort(x);
    dx = diff(x);
    y = y(index);
end

if ~any(dx)
    error(message('SPLINES:SPLINETOOL:onlyonesite'))
end
end  % chckxy

function h = clickable(cf,corner,ewid,id,ecall,userdata)
%CLICKABLE a setup for editing and repeatedly incrementing

% be sure to make id exactly 4 characters long

units = 'normalized';
if nargin<5,
    userdata=[];
end
edy = .0016;
wh = .036;
lx = .018;
h = zeros(4,1);
h(1) = uicontrol('Parent',cf, ...
    'Units',units, ...
    'BackgroundColor',[1 1 1], ...
    'ListboxTop',0, ...
    'Position',[corner(1) corner(2)+wh+3*edy ewid wh], ...
    'UserData',userdata,...
    'Style','edit', ...
    'HorizontalAlignment','left', ...
    'Callback',sprintf( 'splinetool ''%s''', ecall ), ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_ChangeValue')), ...
    'Tag',['edit',id]);
% much prefer the following triple to a slider
h(2)= uicontrol('Parent',cf, ...
    'Units',units, ...
    'Position',[corner(1), corner(2),lx,wh], ...
    'UserData',userdata,...
    'Style','pushbutton', ...
    'String','-', ...
    'TooltipString',getString(message('SPLINES:resources:tooltip_DecreaseValue')), ...
    'Callback','splinetool ''pm''',...
    'Tag',['minus',id]);
h(3) = uicontrol('Parent',cf, ...
    'Units',units, ...
    'BackgroundColor',[1 1 1], ...
    'Position',[corner(1)+lx,corner(2),ewid-2*lx,wh], ...
    'UserData',userdata,...
    'Style','edit', ...
    'HorizontalAlignment','left', ...
    'String','.1', ...
    'TooltipString',getString(message('SPLINES:resources:tooltip_Increment')), ...
    'Callback','splinetool ''increment''', ...
    'Tag',['increment',id]);
h(4)  = uicontrol('Parent',cf, ...
    'Units',units, ...
    'Position',[corner(1)+ewid-lx,corner(2),lx,wh], ...
    'UserData',userdata,...
    'Style','pushbutton', ...
    'String','+', ...
    'TooltipString',getString(message('SPLINES:resources:tooltip_IncreaseValue')), ...
    'Callback','splinetool ''pm''',...
    'Tag',['plus',id]) ;
end  % clickable

function mess = concat(mess1,mess2)
%CONCAT  two cell arrays containing strings

mess = cell(length(mess1)+length(mess2),1);
[mess{:}] = deal(mess1{:},mess2{:});
end  % concat

function output = iEvaluateEditField( editField, oldValue, returnScalar )
% iEvaluateEditField   Evaluate the string at editfield if possible
%
% If it is possible to evaluate the string then the value of that string is
% returned. If it is not possible, then the output is a string (char-array)
% containing the error message.

string = get(editField,'String');
output = iEvaluateString(string);

if ischar(output)
    % Already an error ==> no more checks required
elseif ~all(isfinite(output))
    output = getString(message('SPLINES:resources:NoNaNsOrInfs'));
elseif ~all( isreal( output ) )
    output = getString(message('SPLINES:resources:NoImaginaryNumbers'));
end

if nargin==3 && returnScalar && ~ischar( output )
    output = output(1);
end

if nargin>1 && ischar(output)
    iCorrectBadEdit( editField, oldValue, output );
end
end  % iEvaluateEditField

function output = iEvaluateString(string)
lastwarn('')
warningCleanup = warningOff( 'all' ); %#ok<NASGU>
try
    output = eval(string);
catch exception
    output = exception.message;
end
lastw = lastwarn;
if ~isempty(lastw),
    output = lastw;
end
end

function iCorrectBadEdit(editField,oldValue,errorMessage)
% iCorrectBadEdit   Correct an edit field where a "bad edit" has been made
iReportBadEdit(editField,errorMessage);
set(editField,'String',oldValue);
end

function iReportBadEdit(editField,errorMessage)
% iReportBadEdit   Report failure of change in edit field
expression = get(editField,'String');

warningString = getString( message( 'SPLINES:resources:dlg_InvalidExpression', ...
    expression, errorMessage ) );

dialogName = getString( message( 'SPLINES:resources:dlgTitle_InvalidExpression') );

warndlg( warningString, dialogName, 'modal' );
end 

function flashedit(fieldhand)
%FLASHEDIT flash the edit field
temp = get(fieldhand,'BackgroundColor');
set(fieldhand,'BackgroundColor',.7*[1,1,1]),
pause(.1)
set(fieldhand,'BackgroundColor',temp)

end  % flashedit

function name = full_name(name)
%FULL_NAME make name exactly 10 characters long, without any embedded blanks
%  and with its deblanked version a valid MATLAB variable name

name = deblank(name);
if ~isvarname(name)
    uiwait(...
        warndlg( getString(message('SPLINES:resources:dlg_InvalidName', name) ), ...
        getString(message('SPLINES:resources:dlgTitle_InvalidName')),'modal'))
    % recover the current name and return it
    name = ''; return
end

lname = length(name);
if lname>10      % truncate the name
    name = name(1:10);
    warndlg(getString(message('SPLINES:resources:dlg_10CharacterName')), ...
        getString(message('SPLINES:resources:dlgTitle_NewName')),'modal')
elseif lname<10  % pad the name with blanks
    name = [name,repmat(' ',1,10-lname)];
end
if ~isempty(findobj('Tag',name))
    uiwait(warndlg( getString(message('SPLINES:resources:dlg_DuplicateName', deblank(name))), ...
        getString(message('SPLINES:resources:dlgTitle_DuplicateName')),'modal'))
    % recover the current name and return it
    name = '';
end
end  % full_name

function get_approx(hand)
%GET_APPROX    compute the current spline
%
% redo the knot sequence according to the current approximation
% use the number of pieces specified
if ~isequal(get(hand.figure,'Pointer'),'watch')
    set(hand.figure,'Pointer','watch'),
    drawnow
end

% pick up the userdata of the current line
lineud = get(hand.nameline,'UserData');

% get the data
x = get(hand.dataline,'XData');
y = get(hand.dataline,'YData');

lineud.method = get(hand.method,'Value');
switch lineud.method
    case 1
        % pick up what end condition was chosen.
        V = get(hand.endconds,'Value');
        
        lineud.endconds(1) = V;
        
        if any([2 3 4 9]==V)  % pick up the numerical endcondition information
            
            tag = get(gcbo,'Tag');
            j = 1;
            if tag(end)=='e',
                j=2;
            end
            if isfield(lineud,'valconds')
                output = iEvaluateEditField( hand.params(2,j), lineud.valconds(j) );
            else
                output = iEvaluateEditField( hand.params(2,j) );
            end
            if ischar(output),
                set(hand.figure,'Pointer','arrow'),
                drawnow
                return
            else
                lineud.valconds(j) = output(1);
                lineud.valconds(3-j) = iEvaluateEditField( hand.params(2,3-j) );
            end
        end
        
        switch V
            case 1 %  'not-a-knot'
                lineud.cs = csapi(x,y);
            case {2,3} %  'clamped', 'complete'
                lineud.cs = csape(x,[lineud.valconds(1),y,lineud.valconds(2)],'complete');
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    sprintf('csape(x,[%g,y,%g],''complete'');',lineud.valconds), ...
                    message( 'SPLINES:resources:BottomLine_SameCommandAs', sprintf('spline(x,[%g,y,%g])',lineud.valconds) ) );
            case 4 %  'second'
                lineud.cs = csape(x,[lineud.valconds(1),y,lineud.valconds(2)],'second');
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    sprintf('csape(x,[%g,y,%g],''second'');',lineud.valconds), ...
                    message( 'SPLINES:resources:BottomLine_SameCommandAs', sprintf('csape(x,[%g,y,%g],[2,2])',lineud.valconds) ) );
            case 5 %  'periodic'
                lineud.cs = csape(x,y,'periodic');
            case {6,7} %  'variational', 'natural'
                lineud.cs = csape(x,y,'variational');
            case 8 %  'Lagrange'
                lineud.cs = csape(x,y);
            case 9 %  'custom'
                tmp = get(hand.params(1,1),'String');
                l = str2double(tmp(1));
                tmp = get(hand.params(1,2),'String');
                r = str2double(tmp(1));
                lineud.cs = csape(x,[lineud.valconds(1),y,lineud.valconds(2)],[l,r]);
                lineud.endconds([2 3]) = [l,r];
                lineud.bottom = iCreateBottomLine( hand.dbname,...
                    sprintf( 'csape(x,[%g,y,%g],[%g,%g]);', lineud.valconds, l, r ), ...
                    message( 'SPLINES:resources:BottomLine_DifferentEndConditions' ) );
        end %switch V
        
    case 2 % combine both cubic and quintic smoothing spline.
        
        % Decide on whether to use csaps or spaps; it will depend on how we got here.
        % If the smoothing parameter was reset, we use
        %    csaps for order 4,  spaps for order 6
        % If the smoothing tolerance was reset, we use spaps
        % If a datum was added, deleted, or changed, or a weight was changed,
        %           we use the previously used one.
        % But, to begin with, we use   csaps(x,y,[],[],w)
        
        tag = get(gcbo,'Tag');  % find out what button was pushed
        
        % the default weights are the trapezoidal weights (as in spaps)
        trapweights = 0;
        if ~isfield(lineud,'w')||any(tag=='_')||isequal(tag(end-3:end),'clkl')
            trapweights = 1;
            dx = diff(x);
            lineud.w = ([dx 0]+[0 dx])/2;
            lineud.wc = [];
            lineud.wc(1) = iAddCommentedChange( hand.currentline, ...
                'dx = diff(x);\nweights = ([dx 0]+[0 dx])/2;', ...
                message( 'SPLINES:resources:comment_TrapezoidalErrorWeights' ) );
        end
        
        if ~strcmp(tag,'method') % find out what call was previously made
            whichcall = lineud.bottom(strfind(lineud.bottom(1:14), ' = ')+(3:4));
        end
        
        switch tag
            
            case {'method','undo'} % we start from scratch
                
                lineud.par = -1;
                whichcall = 'cs';
                lineud.tol = 0;
                
            case {'minusleft','editleft','plusleft'}% we specified the smoothing par ...
                
                output = iEvaluateEditField( hand.params(2,1), shortstr(lineud.par,'',1), true );
                if ischar(output),
                    set(hand.figure,'Pointer','arrow')
                    drawnow
                    return
                else % make sure this value is in the interval [0 .. 1]
                    lineud.par = max(0,min(1,output));
                end
                
                switch get(hand.order,'Value')
                    case 1
                        whichcall = 'cs';
                    case 2
                        whichcall = 'sp';
                        % we must translate the parameter into a rho or tol
                        if lineud.par==1
                            lineud.tol(1) = 0;
                        elseif lineud.par==0
                            lineud.tol(1) = sum((lineud.w).*(y.*y));
                        else
                            lineud.tol(1) = lineud.par/(lineud.par-1);
                        end
                end
                
            case {'add_item','del_item', 'minusclkl','editclkl','plusclkl'}
                
                % lineud.tol(2:end) = [];
                
            case {'minusclkr','editclkr','plusclkr'}
                
                if get(hand.data_etc,'Value')==3
                    % we must update the add'l part of tolerance
                    V = get(hand.params(1,5),'Value');
                    if V==length(x) % attempt to change the NaN entry
                        set(hand.params(2,5),'String',NaN)
                        warndlg(getString(message('SPLINES:resources:dlg_CannotChangeLastEntry')), ...
                            getString(message('SPLINES:resources:dlgTitle_RoughnessWeight')),'modal')
                        set(hand.figure,'Pointer','arrow')
                        drawnow
                        return
                    end
                    temp = get(hand.params(1,5),'String');
                    output = iEvaluateEditField( hand.params(2,5), eval(temp(V,:)) );
                    if ischar(output),
                        set(hand.figure,'Pointer','arrow')
                        drawnow 
                        return
                    else  % check that this new jump value is ok; if it is less than
                        % the previous value, it may have to be raised
                        if length(output)>1 % make sure that output is a scalar
                            output = output(1);
                            set(hand.params(2,5),'String',output)
                        end
                        change = output - lineud.tol(V+1);
                        if V>1,
                            change = change + lineud.tol(V);
                        end
                        if change<0
                            [changed,ich] = max([change, (1e-10)-min(lineud.tol(V+1:end))]);
                            % note the positive lower bound (1e-10) imposed on lambda
                            if ich>1
                                if (changed-change)>abs(output)*1e-4
                                    warndlg( ...
                                        getString(message('SPLINES:resources:dlg_PositiveRoughnessWeight', ...
                                        num2str(output), num2str(output+changed-change))),...
                                        getString(message('SPLINES:resources:dlgTitle_InvalidRoughnessWeight')),'modal')
                                end
                                % modify output now, since it may end up in that file
                                output = output+changed-change;
                                change = changed;
                            end
                        end
                        lineud.tc(end+1) = addchange(hand.currentline, ...
                            ['dlam(',num2str(V),') = ',num2str(output,15),';',...
                            ' %% then you changed some roughness weight']);
                        lineud.tol(V+1:end) = lineud.tol(V+1:end)+change;
                        set(hand.params(1,5),'String', ...
                            [lineud.tol(2), diff(lineud.tol(2:end)),NaN])
                    end
                    
                end
                
            case {'minusrite','editrite','plusrite'} % the tolerance was modified
                
                output = iEvaluateEditField( hand.params(2,2), lineud.tol(1), true );
                if ischar(output),
                    set(hand.figure,'Pointer','arrow'),
                    drawnow
                    return
                else
                    lineud.tol(1) = output;
                end
                
                % for the time being, do not allow explicit specification of rho
                if lineud.tol(1) < 0
                    lineud.tol(1) = 0;
                    set(hand.params(2,2),'String','0');
                    warndlg(sprintf('%s\n\n%s',...
                        getString(message('SPLINES:resources:dlg_NegativeTolerance')),...
                        getString(message('SPLINES:resources:dlg_NegativeToleranceLine2'))),...
                        getString(message('SPLINES:resources:dlgTitle_NegativeTolerance')),'modal')
                end
                
                whichcall = 'sp';
                
            case 'order'
                
                if get(hand.order,'Value')==2,
                    whichcall = 'sp';
                end
                
            otherwise
                errordlg(getString(message('SPLINES:resources:dlg_InSmoothingButton',tag)), ...
                    getString(message('SPLINES:resources:dlgTitle_InvalidState')),'modal')
        end %switch tag
        
        switch whichcall
            
            case 'cs'
                [lineud.cs,p_used] =  ...
                    csaps(x,y,[lineud.par,lineud.tol(2:end)],[],lineud.w);
                if lineud.par<0 % since the smoothing parameter has changed, yet we
                    % use subsequently only its rounded value as stored in
                    % the display, we need to re-run for consistency
                    [lineud.cs,p_used] =  ...
                        csaps(x,y,[eval(shortstr(p_used)),lineud.tol(2:end)],[],lineud.w);
                end
                lineud.tol(1) = sum((lineud.w).*((y-fnval(lineud.cs,x)).^2));
                parinfo = num2str(lineud.par,12);
                dlaminfo = message.empty();
                moreparinfo = message( 'SPLINES:resources:BottomLine_EnforceSmoothingParameter', 'csaps' );
                if lineud.par<0
                    moreparinfo = message( 'SPLINES:resources:BottomLine_ChooseSmoothingParameter' );
                end
                lineud.par = p_used;
                if trapweights
                    weightinfo = message('SPLINES:resources:BottomLine_TrapezoidalRule');
                else
                    weightinfo = message('SPLINES:resources:BottomLine_Weights');
                end
                if isfield(lineud,'tc')&&length(lineud.tc)>1
                    parinfo = ['[',parinfo,',cumsum(dlam)]',]; 
                    dlaminfo = message('SPLINES:resources:BottomLine_JumpsInRoughnessWeight');
                end
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    sprintf( 'csaps(x,y,%s, [], weights);', parinfo ), ...
                    [moreparinfo, weightinfo, dlaminfo] );
                
            case 'sp'
                
                maintext = message('SPLINES:resources:BottomLine_EnforceTolerance');
                tolinfo = num2str(lineud.tol(1),12);
                
                lineud.bottom = '';
                lastwarn(''),
                warningCleanup = warningOff( 'SPLINES:SPAPS:toltoolow' ); %#ok<NASGU>
                switch get(hand.order,'Value')
                    case 1
                        minfo = '';
                        [lineud.cs,~,rho] = spaps(x,y,lineud.tol,lineud.w);
                        if isfinite(rho),
                            lineud.par = rho/(1+rho);
                        else
                            lineud.par = 1;
                        end
                    case 2
                        minfo = ',3';
                        if length(x)<3
                            errordlg(getString(message('SPLINES:resources:dlg_SmoothingSpline6thOrder')))
                        else
                            [lineud.cs,~,rho] = spaps(x,y,lineud.tol,lineud.w,3);
                            if isfinite(rho),
                                lineud.par = rho/(1+rho);
                            else
                                lineud.par = 1;
                            end
                        end
                        
                        if isequal(tag(end-3:end),'left') % we must update lineud.tol, and the text
                            lineud.tol(1) = sum((lineud.w).*((y-fnval(lineud.cs,x)).^2));
                            maintext = message('SPLINES:resources:BottomLine_EnforceSmoothingParameter','spaps');
                        end
                end %switch get(hand.order,'Value')
                lastw = lastwarn;
                warning('on','SPLINES:SPAPS:toltoolow')
                if ~isempty(lastw)
                    warndlg(getString(message('SPLINES:resources:dlg_CannotMeetTolerance')), ...
                        getString(message('SPLINES:resources:dlgTitle_CannotMeetTolerance')),'modal')
                    lineud.tol(1) = sum((lineud.w).*((y-fnval(lineud.cs,x)).^2));
                end
                
                if isempty(lineud.bottom)
                    lastinfo = message.empty();
                    if isfield(lineud,'tc')&&length(lineud.tc)>1
                        tolinfo = ['[',tolinfo,',cumsum(dlam)]'];
                        lastinfo = message('SPLINES:resources:BottomLine_JumpsInRoughnessWeight');
                    end
                    if isfield(lineud,'wc')&&length(lineud.wc)>1
                        tolinfo = [tolinfo,',weights'];
                        lastinfo = [message('SPLINES:resources:BottomLine_Weights'),lastinfo];
                    end
                    lineud.bottom = iCreateBottomLine( hand.dbname, ...
                        sprintf( 'spaps(x,y,%s%s);', tolinfo, minfo ), ...
                        [maintext, lastinfo] );
                end
            otherwise
                errordlg(getString(message('SPLINES:resources:dlg_InSmoothingCall',whichcall)), ...
                    getString(message('SPLINES:resources:dlgTitle_InvalidState')),'modal')
        end %switch whichcall
        
    case 3  % least-squares approximation
        
        www = '';
        if isfield(lineud,'w')&&any(lineud.w~=1),
            www = ', weights';
        end
        moved = 0;
        tag = get(gcbo,'Tag');  % find out what button was pushed
        switch tag
            case {'method' , 'order' , ...
                    'minusclkl','editclkl','plusclkl','minusclkr','editclkr','plusclkr',...
                    'add_item','rep_knot','del_item','undo', ...
                    'minusclkm','editclkm','plusclkm'}
                
                if ~isfield(lineud,'w')
                    lineud.w = ones(size(x));
                    lineud.wc = [];
                    lineud.wc(1) = iAddCommentedChange( hand.currentline, ...
                        'weights = ones(size(x));',...
                        message( 'SPLINES:resources:comment_UniformErrorWeights' ) );
                end
                
                if ~isfield(lineud,'knots')
                    % we've just switched into l2; start with no interior knots
                    lineud.k = min(4,length(x));
                    strk = num2str(lineud.k);
                    lineud.bottom = iCreateBottomLine( hand.dbname, ...
                        sprintf( 'spap2(1,%s,x,y%s);', strk, www ), ...
                        message( 'SPLINES:resources:BottomLine_StartingWithLeastSquaresOrder', strk ) );                        
                    lineud.knots = augknt(x([1 end]),lineud.k);
                    lineud.kc = [];
                    set(hand.order,'Value',lineud.k)
                else
                    moved = 1;
                    lineud = update(hand,'knots',lineud);
                    lineud.bottom = iCreateBottomLine( hand.dbname, ...
                        sprintf( 'spap2(knots,%s,x,y%s);', num2str(lineud.k), www ), ...
                        message( 'SPLINES:resources:BottomLine_LeastSquaresApproximation' ) );
                end
                
            case 'buttonm'  % we are to get a new set of knots via newknt
                
                lineud.knots = newknt(lineud.cs);
                lineud = update(hand,'fit',lineud);
                lineud.kc(end+1) = addchange(hand.currentline, ...
                    ['knots = newknt(',hand.dbname,'); ', ...
                    getString(message('SPLINES:resources:command_BetterKnot'))]);
                set(hand.params(1,4),'String',lineud.knots(:))
                iMarkBreak(hand),
                set_bdisplay(lineud.knots,hand)
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    sprintf( 'spap2(newknt(%s),%s,x,y%s);', hand.dbname, num2str(lineud.k), www ), ...
                    message( 'SPLINES:resources:BottomLine_UseNewKnotToImproveKnots' ) );
                lineud.kc(end+1) = addchange(hand.currentline, ...
                    [hand.dbname,' = spap2(knots, ',...
                    num2str(lineud.k),',x,y',www,');', ...
                    ' %% ... in the least-squares approximation computed now']);
                moved = 1;
                
            case 'piecem' % we are to choose knots for a given number of pieces
                
                lineud.knots = eval(get(hand.piecem,'String'));
                lineud.kc = [];
                moved = 1;
                
            otherwise
                errordlg(getString(message('SPLINES:resources:dlg_InLeastsquaresButton',tag)), ...
                    getString(message('SPLINES:resources:dlgTitle_InvalidState')),'modal')
        end %switch tag
        
        if moved
            lastwarn(''),
            warningCleanup = warningOff( 'all' ); %#ok<NASGU>
            try
                newcs = spap2(lineud.knots,lineud.k,x,y,lineud.w);
            catch laster
                newcs = laster.message;
            end
            lastw = lastwarn;
            if ~isempty(lastw)
                errordlg(sprintf('%s: \n%s',...
                    getString(message('SPLINES:resources:dlg_BadOrder')),...
                    lastw),...
                    getString(message('SPLINES:resources:dlgTitle_BadOrder')),'modal')
            end
            if ischar(newcs)
                switch tag
                    case 'order'
                        lineud.k = fnbrk(lineud.cs,'order');
                        set(hand.order,'Value',lineud.k)
                        errmss = getString(message('SPLINES:resources:dlg_TooHighOrder'));
                    case 'del_item'
                        errmss = getString(message('SPLINES:resources:dlg_DeletionChangeKnotSequence'));
                        lineud.cs = spap2(1,lineud.k,x,y,lineud.w);
                        lineud.knots = fnbrk(lineud.cs,'knots');
                        lineud.bottom = iCreateBottomLine( hand.dbname, ...
                            sprintf( 'spap2(1,%s,x,y%s);', num2str(lineud.k), www ), ...
                            message('SPLINES:resources:BottomLine_DeleteDataPointToDefaultKnot' ) );
                        lineud.kc = [];
                        %  lineud.kc(end+1) = addchange(hand.currentline, ...
                        %     ['knots = augknt(knots([1 end],fnbrk(',hand.dbname, ...
                        %      ',''order'')));']);
                    otherwise
                        errmss = getString(message('SPLINES:resources:dlg_FailedKnotSequenceAny'));
                        lineud.knots = fnbrk(lineud.cs,'knots');
                end
                errordlg( {''; errmss; ''; newcs}, ...
                    getString(message('SPLINES:resources:dlgTitle_BadMove')),'modal')
                set(hand.params(1,4),'String',lineud.knots(:),'Value',1+lineud.k)
                iMarkBreak(hand),
                set_bdisplay(lineud.knots,hand)
            else
                lineud.cs = newcs;
                if length(lineud.knots)==1 % we only specified the number of pieces
                    lineud.bottom = iCreateBottomLine( hand.dbname, ...
                        sprintf( 'spap2(%s,%s,x,y%s);', num2str(lineud.knots), num2str(lineud.k), www ), ...
                        message( 'SPLINES:resources:BottomLine_NumberOfPieces' ) );
                    lineud.knots = fnbrk(newcs,'knots');
                    if length(lineud.knots)>2*lineud.k
                        set(hand.buttonm,'Visible','on')
                    else
                        set(hand.buttonm,'Visible','off')
                    end
                    set(hand.params(1,4),'String',lineud.knots(:),'Value',1+lineud.k)
                    set(hand.params(4,4), ...
                        'String',(x(end)-x(1))/(10*length(lineud.knots)))
                    iMarkBreak(hand),
                    set_bdisplay(lineud.knots,hand)
                end
            end
        else
            lineud.cs = spap2(lineud.knots,lineud.k,x,y);
        end
        
        % set the number of pieces in the piecem display
        set(hand.piecem,'String',length(find(diff(lineud.knots))>0))
        
    case 4  % spline interpolation
        
        moved = 0;
        if ~isfield(lineud,'knots')
            % we've just switched into spline interpolation;
            %  start with the default knot choice
            lineud.bottom =  iCreateBottomLine( hand.dbname,'spapi(4,x,y);', ...
                message( 'SPLINES:resources:BottomLine_CubicSplineInterpolant' ) );
            lineud.knots = aptknt(x,4);
            lineud.kc = [];
            lineud.k = length(lineud.knots) - length(x);
            set(hand.order,'Value',lineud.k)
            set(hand.params(1,4),'String',lineud.knots(:),'Value',1+lineud.k)
            iMarkBreak(hand)
        else
            switch get(gcbo,'Tag')
                case {'order','method','add_item','del_item'}
                    [lineud.knots, lineud.k] = aptknt(x,lineud.k);
                    strk = num2str(get(hand.order,'Value'));
                    lineud.bottom = iCreateBottomLine( hand.dbname, ...
                        sprintf( 'spapi(%s,x,y);', strk ), ...
                        message( 'SPLINES:resources:BottomLine_UseKnotsSuppliedBy', sprintf( 'aptknt(x,%s)', strk ) ) );
                otherwise
                    moved = 1;
                    lineud.bottom = iCreateBottomLine( hand.dbname, 'spapi(knots,x,y);', ...
                        message( 'SPLINES:resources:BottomLine_UseKnotsShownInDataDisplay' ) );
            end
        end
        
        if moved
            lastwarn('')
            warningCleanup = warningOff( 'all' ); %#ok<NASGU>
            try
                newcs = spapi(lineud.knots,x,y);
            catch laster
                newcs = laster.message;
            end
            lastw = lastwarn;
            if ~isempty(lastw),
                newcs = lastwarn;
            end
            if ischar(newcs)
                er=errordlg({getString(message('SPLINES:resources:dlg_FailedKnotSequence'));'';...
                    newcs},getString(message('SPLINES:resources:dlgTitle_BadMove')),'modal');
                lineud.knots = fnbrk(lineud.cs,'knots');
                waitfor(er)
                set(hand.params(1,4),'String',lineud.knots(:))
                iMarkBreak(hand),
                set_bdisplay(lineud.knots,hand)
            else
                lineud.cs = newcs;
            end
        else
            lineud.cs = spapi(lineud.knots,x,y);
        end
end %switch lineud.method

currentplot = fnplt(lineud.cs);
set(hand.currentline, ...
    'XData',currentplot(1,:),'YData',currentplot(2,:))
% generate the first two derivatives and their end values
lineud.dcs = fnder(lineud.cs);
lineud.ddcs = fnder(lineud.dcs);
ends = fnbrk(lineud.cs,'interval');
lineud.ends = [fnval(lineud.dcs,ends);fnval(lineud.ddcs,ends)];
set(hand.nameline, ...
    'XData',currentplot(1,:), 'YData',currentplot(2,:), ...
    'UserData',lineud);

% also take care of second view
set_view(hand),
set_view_label(hand.name,hand)

set_displays(hand)

end  % get_approx

function isf = get_isf(yname,x)
%GET_ISF check whether yname is a legal function, returning
%        1   for a file, -1 if it doesn't work for function values from x
%        2   for a built-in function, -2 if it doesn't work
%        0   otherwise

if ~isvarname(yname),
    isf = 0; return,
end

b = which(yname);
if length(b)>1&&b(end-1)=='.'&&(b(end)=='m'||b(end)=='M')
    % this is the name of a file; let's hope it
    % supplies y for given x.
    isf = 1;
else
    if length(b)>7&&isequal(b(1:8),'built-in')
        % it is a built-in function, of one variable I hope
        isf = 2;
    else
        isf = 0;
    end
end

if isf
    try
        feval(yname,x);
    catch  %#ok<CTCH> ignore MException
        isf = -isf;
    end
end
end  % get_isf

function names = get_names(cnames)
%GET_NAMES  temporary way for recovering the names

if isempty(cnames{1})
    names = [];
else
    for j=size(cnames,1):-1:1, names(j,:) = cnames{j}; end
end
end  % get_names

function [x,y] = ginput(hand)
%GINPUT local version of ginput, to display coordinates

% set up things
if get(hand.data_etc,'Value')==1
    hands = hand.params(2,[3 5]);
else
    hands = hand.params(2,4);
end
cf = hand.figure;


% While the new point to be added is selected deactivate all the uicontrols
% and menus in the GUI
cleanupUicontrolEnable = temporarySet( ...
    findobj( cf, 'Type', 'uicontrol' ), 'Enable', 'off' ); %#ok<NASGU>
cleanupUimenuEnable = temporarySet( ...
    findobj( cf, 'Type', 'uimenu' ), 'Enable', 'off' ); %#ok<NASGU>
% ... except for the textboxes that get updated with current position. For
% those controls, just make them inactive.
set( hands, 'Enable', 'inactive ' );

% Because we have are going to mess with Figure's UserData we need to
% redirect the CloseRequestFcn
cleanupCloseRequestFcn = temporarySet( cf, 'CloseRequestFcn', '' ); %#ok<NASGU>


savehand = hand; % temporarily use the figure's userdata to store the handle
% of the edit window(s) that should show the currentpoint coords
state = uisuspend(cf);
set(cf,...
    'UserData', hands, ...
    'WindowButtonMotionFcn','splinetool(''ginputmove'')',...
    'WindowButtonDownFcn','splinetool(''ginputdone'')', ...
    'Pointer','crosshair')

x = [];
y = [];

while ishandle(cf)
    if isequal(get(cf,'Pointer'),'arrow')
        x = eval(get(hands(1),'String'));
        if length(hands)>1
            y = eval(get(hands(2),'String'));
        else
            y = 0;
        end
        set(cf,'UserData',savehand)
        uirestore(state)
        return
    end
    pause(.001)
end
end  % ginput

function cleanup = temporarySet( obj, property, value )
% temporarySet -- Temporary set a property of an HG object
%
% OBJ can be an array or a scalar
% PROPERTY must be a scalar string
% VALUE must be a single value for the property
%
% The property is reset to the old value when the "cleanup" object is
% deleted.
oldValue = get( obj, {property} );
cleanup = onCleanup( @() set( obj, {property}, oldValue ) );

set( obj, property, value );
end  % temporarySet

function values = given(x,hand)
%GIVEN   evaluate the given function

values = feval(get(get(hand.Axes(1),'YLabel'),'String'),x);
end  % given

function highlightn(clickp,hand)
%HIGHLIGHTN  highlight the point nearest CLICKP

% find the nearest data point
x = get(hand.dataline,'XData');
y = get(hand.dataline,'YData');
% since the user only sees the window as is, the data point
% closest to the clicked point should be determined in the
% physical coordinates rather than those of the data.
[~,V] = ...
    min((([x(:) y(:)]-repmat(clickp(1,1:2),length(x),1)).^2)*...
    reshape(([2 1]./diff(reshape(axis,2,2))).^2,2,1));
if get(hand.params(1,3),'Value')~=V || length(get(hand.highlightxy,'XData'))>1
    set(hand.params(1,3),'Value',V),
    iMarkDataPoint(hand)
end
end  % highlightn

function insert_and_mark(x,y,xx,yy,hand)
%INSERT_AND_MARK

[x,i] = sort([x xx]);
tmp = [y yy];
y = tmp(i);

% record the change operation in changes
ii = find(diff(i)<0);
if isempty(ii)
    ii = length(x)+1;
end
si = num2str(ii);
change = [
    sprintf( 'x = [x(1:%s-1),%s,x(%s:end)]; ', si, num2str(xx,15), si ), ...
    sprintf( 'y = [y(1:%s-1),%s,y(%s:end)];',  si, num2str(yy,15), si )
    ];

if isequal(get(gcbo,'Tag'),'add_item')
    cindex = iAddCommentedChange( hand.currentline, change, ...
        message( 'SPLINES:resources:comment_AddedDataPoint' ) );
else
    % we supplied earlier the first part of this change, and now finish it.
    cindex = iAppendCommentedChange( hand.currentline, change, ...
        message( 'SPLINES:resources:comment_MovedDataPoint' ) );
end

% make the added point the current one
V = find(i==length(x));
set(hand.params(1,3),'Value',V);

% adjust the weights, if any
lineud = get(hand.nameline,'UserData');
if isequal(get(gcbo,'Tag'),'add_item')
    if isfield(lineud,'w')
        if length(lineud.wc)==1 % we are using a standard weight;
            % simply let method 2 or 3 start the weight again
            lineud = rmfield(lineud,'w');
            lineud.wc=[];
        else % we make up the corresponding weight
            lineud.w = [lineud.w(1:ii-1),(lineud.w(ii-1)+lineud.w(ii))/2,lineud.w(ii:end)];
            lineud.wc(end+1) = iAddCommentedChange( hand.currentline, ...
                sprintf( 'weights = [weights(1:%s-1),(weights(%s-1)+weights(%s))/2,weights(%s:end)];', si, si, si, si ), ...
                message( 'SPLINES:resources:comment_InventErrorWeightEntry' ) );
        end
    end
    if isfield(lineud,'tc')  % we have roughness weights in place
        lineud.tol = [lineud.tol(1:ii-1),(lineud.tol(ii-1)+lineud.tol(ii))/2, lineud.tol(ii:end)];
        
        lineud.tc(end+1) = iAddCommentedChange( hand.currentline, ...
            sprintf( 'dlam = [dlam(1:%s-1),0,dlam(%s:end)];', si, si ), ...
            message( 'SPLINES:resources:comment_InsertZeroJumpForRoughness' ) );
    end
else
    if isfield(lineud,'w')
        lineud = rmfield(lineud,'w');
        lineud.wc = [];
    end
    if isfield(lineud,'tol'),
        lineud.tol(2:end)=[];
        lineud.tolc = [];
    end
end
% re-initialize the knots if necessary
if lineud.method==4
    lineud = rmfield(lineud,'knots');
    lineud.kc = [];
end
% also augment the data changes vector
lineud.dc(end+1) = cindex;
set(hand.nameline,'UserData',lineud);
set(hand.data_etc,'UserData',cindex);

set_data(hand,x,y)
iMarkDataPoint(hand)

end  % insert_and_mark

function iMarkBreak(hand)
% iMarkBreak   Highlight the marked break

V = get(hand.params(1,4),'Value');

breaks = get(hand.params(1,4),'String');
ylim = get(hand.Axes(1),'YLim');

% flash the edit field if pertinent
tag = get(gcbo,'Tag');
lineud = get(hand.nameline,'UserData');
if length(tag)==5&&tag(5)=='m'&&isfield(lineud,'k')&&...
        V>lineud.k&&V<=length(lineud.knots)-lineud.k
    flashedit(hand.params(2,4))
end

set(hand.params(2,4),'String',breaks(V,:))
breaks = str2num(breaks); %#ok<ST2NM> breaks is a vector
set(hand.highlightb, 'XData', breaks([V V]), 'YData', ylim);
end  % iMarkBreak

function iMarkDataPoint(hand)
% iMarkDataPoint   Highlight the marked data point

tag = get(gcbo,'Tag');
if length(tag)==5&&tag(5)=='r'
    listt = hand.params(1,5);
    listu = hand.params(1,3);
else
    listt = hand.params(1,3);
    listu = hand.params(1,5);
end

if length(tag)==5
    switch tag(5)
        case 'l',
            temp1 = 3;
        case 'r',
            temp1 = 5;
    end
    if exist('temp1','var'),
        flashedit(hand.params(2,temp1)),
    end
end

V = get(listt,'Value');
set(listu,'Value',V);
% set(listu,'ListboxTop', get(listt,'ListboxTop'));
x = get(hand.dataline,'XData');
y = get(hand.dataline,'YData');
set(hand.highlightxy, 'XData',x(V), 'YData',y(V))

% also update the edit fields
tmp = get(hand.params(1,3),'String');
set(hand.params(2,3),'String',tmp(V,:))
tmp = get(hand.params(1,5),'String');
set(hand.params(2,5),'String',tmp(V,:))

end  % iMarkDataPoint

function menu(cf,varargin)
%MENU my own much more pliable version of MATLAB's menu command

depth = 0.8;
width = 0.4;
margo2 = (1-width)/2;
inter = 0.01;
bh = min(0.09,(depth/nargin)-inter);
handles = zeros(1,nargin-1);

nt = 0;
for j=1:size(handles,2)
    handles(j) = uicontrol('Parent',cf, ...
        'Units','normalized', ...
        'Position',[margo2, 0.98-j*(bh+inter), width, bh], ...
        'String',varargin{j});
    
    if iscell(varargin{j}) % make it a text box
        nt = nt+1;
        set(handles(j),'Style','text', ...
            'BackgroundColor',get(cf,'Color'))
        
    else % make it a button
        set(handles(j), ...
            'Callback', ['set(gcf,''Pointer'',''watch''),drawnow,', ...
            'splinetool(''startcont'',',num2str(j-nt),')']);
    end
end

set(cf,'UserData',{cf,handles})

end  % menu

function iSetupMethod(hand)
% iSetupMethod   Set things up for a particular method


M = get(hand.method,'Value');
if M==2 % initialize the order display
    set(hand.order,'Value',1)
end
lineud = get(hand.nameline,'UserData');
if ~isfield(lineud,'method')     %isempty(lineud)
    M0 = 0;
else
    M0 = lineud.method;
end

if M==4 % average repeated data sites if user okays it
    x = get(hand.dataline,'XData');
    if ~all(diff(x))
        answer = questdlg(getString(message('SPLINES:resources:dlg_AveragedDataPoints')), ...
            getString(message('SPLINES:resources:dlgTitle_RepeatedDataSites')), ...
            getString(message('SPLINES:resources:uicontrol_OK')),...
            getString(message('SPLINES:resources:uicontrol_Cancel')),...
            getString(message('SPLINES:resources:uicontrol_OK')));
        if isempty(answer) || strcmp(answer,getString(message('SPLINES:resources:uicontrol_Cancel')))
            set(hand.method,'Value',M0);
            return
        end
        
        currentx = x(get(hand.params(1,3),'Value'));
        [x,y] = chckxywp(x,get(hand.dataline,'YData'));
        set(hand.params(1,3),'Value',find(x==currentx));
        % record the change operation in changes
        change = '[x,y] = chckxywp(x,y);';
        cindex = addchange(hand.currentline,[change, ...
            getString(message('SPLINES:resources:command_AveragedDataPoints'))]);
        if isfield(lineud,'w'),
            lineud = rmfield(lineud,'w');
            lineud.wc = [];
        end
        if isfield(lineud,'tol'),
            lineud.tol(2:end)=[];
            lineud.tolc = [];
        end
        lineud.dc(end+1) = cindex;
        set(hand.nameline,'UserData',lineud);
        set(hand.data_etc,'UserData',cindex);
        
        set_data(hand,x,y)
        iMarkDataPoint(hand)
        
    end
end

if M~=M0,
    set_edits(M,hand),
end

parameters(hand)

end  % iSetupMethod

function moved = move_knot(hand)
%MOVE_KNOT

moved = 0;

V = get(hand.params(1,4),'Value');
lineud = get(hand.nameline,'UserData');
if V<=lineud.k || V>length(lineud.knots)-lineud.k
    warndlg(getString(message('SPLINES:resources:dlg_OnlyModifyInteriorKnots')), ...
        getString(message('SPLINES:resources:ModifyKnots')),'modal')
    set(hand.params(2,4),'String',lineud.knots(V))
    return
end

output = iEvaluateEditField( hand.params(2,4), lineud.knots(V), true );
if ischar(output)
    return
else
    knot = output;
end

% make sure this knot is still interior
if lineud.knots(1)>=knot || lineud.knots(end)<=knot
    warndlg(getString(message('SPLINES:resources:dlg_CannotMoveKnotOutside')), ...
        getString(message('SPLINES:resources:dlgTitle_TheKnotMustRemainInterior')),'modal')
    return
end

lineud = update(hand,'knots');
lineud.knots(V) = [];
sV = num2str(V);
[lineud.knots,i] = sort([lineud.knots, knot]);
set(hand.params(1,4),'Value',find(i==length(lineud.knots)), ...
    'String',lineud.knots(:))

lineud.kc(end+1) = iAddCommentedChange( hand.currentline, ...
    sprintf( 'knots(%s)=[]; knots = sort([knots,%s]);', sV, num2str(knot,15) ), ...
    message( 'SPLINES:resources:comment_ReplaceKnot' ) );

set(hand.nameline,'UserData',lineud)

iMarkBreak(hand),
set_bdisplay(lineud.knots,hand)
moved = 1;
end  % move_knot

function move_point(hand)
%MOVE_POINT % replace the current point by the point specified in the edit

x = get(hand.dataline,'XData');
V = get(hand.params(1,3),'Value');
output = iEvaluateEditField( hand.params(2,3), x(V), true );
if ischar(output)
    return
else
    xx = output;
end
dox = false;
if (V==1&&x(1)~=xx)||(V==length(x)&&x(end)~=xx)
    h=warndlg(getString(message('SPLINES:resources:dlg_CannotChangeExtremeDataSites')), ...
        getString(message('SPLINES:resources:dlgTitle_ApproximationChange')),'modal');
    uiwait(h)
elseif xx<x(1)||xx>x(end)
    h=warndlg(getString(message('SPLINES:resources:dlg_CannotMoveBeyondExtreme')),...
        getString(message('SPLINES:resources:dlgTitle_ApproximationChange')),'modal');
    uiwait(h)
elseif get(hand.method,'Value')==4 && any(x==xx)
    h=warndlg(getString(message('SPLINES:resources:dlg_AveragedDataPoints')), ...
        getString(message('SPLINES:resources:dlgTitle_RepeatedDataSites')), 'modal');
    uiwait(h)
else
    
    dox = true;
    doy = true;
    % tell user, if needed, that a move will reset all weights
    lineud = get(hand.nameline,'UserData');
    if ~isfield(lineud, 'nowarn')&& ...
            ((isfield(lineud,'wc')&&length(lineud.wc)>1)||...
            (isfield(lineud,'tc')&&length(lineud.tc)>1))
        switch questdlg(...
                getString(message('SPLINES:resources:dlg_ResetWeights')), ...
                getString(message('SPLINES:resources:dlgTitle_ResetAllWeights')), ...
                getString(message('SPLINES:resources:uicontrol_No')),...
                getString(message('SPLINES:resources:uicontrol_Yes')),...
                getString(message('SPLINES:resources:uicontrol_DontAskAgain')),...
                getString(message('SPLINES:resources:uicontrol_No')));
            case {getString(message('SPLINES:resources:uicontrol_No')),''}
                dox = false;
                doy = false;
            case getString(message('SPLINES:resources:uicontrol_Yes'))
            otherwise
                lineud.nowarn = 1;
                set(hand.nameline,'UserData',lineud)
        end
    end
    
    y = get(hand.dataline,'YData');
    if ~doy % restore edit field to its former value
        set(hand.params(2,5),'String',y(V))
    else
        x(V)=[];
        y(V) = [];
        yold = y(V);
        if get(hand.dataline,'UserData')
            yy = given(xx,hand);
        else
            output = iEvaluateEditField( hand.params(2,5), yold, true );
            if ischar(output)
                return
            else
                yy = output;
            end
        end
        
        % record the deletion in changes:
        sV = num2str(V);
        addchange(hand.currentline, ['x(',sV,')=[]; y(',sV,')=[];']);
        
        insert_and_mark(x,y,xx,yy,hand)
        get_approx(hand)
    end
    
end
if ~dox % restore edit field to its former value
    set(hand.params(2,3),'String',x(V))
end
end  % move_point

function hand = iNewSpline(hand, startmethod)
% iNewSpline   Start a new spline fit, using the not-a-knot end conditions
[hand.name, hand.nameline] = add_to_list(hand);
hand.dbname = deblank(hand.name);
set(hand.figure,'UserData',hand)
xy = get(hand.highlightxy,'UserData');
set(hand.dataline,'XData',xy(1,:),'YData',xy(2,:));
set(hand.params(1,3),'Value',1)
lineud.dc = 0;
set(hand.nameline,'UserData',lineud)
set(hand.data_etc,'UserData',0)

set([hand.method,hand.endconds],'Value',1)
if nargin>1,
    set(hand.method, 'Value',startmethod),
end
iSetupMethod(hand)

set_legend(hand,hand.Axes(1))

end  % iNewSpline

function ok = okvar(varname)
%OKVAR Is VARNAME legal? Is it ok to overwrite it in base workspace?

% check whether VARNAME is a legal variable name.
if ~isvarname(varname)
    uiwait(errordlg( ...
        getString(message('SPLINES:resources:dlg_InvalidVariable', varname )),...
        getString(message('SPLINES:resources:dlgTitle_Error')),'modal'))
    ok = 0;
    return
end

ok = 1;
if evalin('base',['exist(''',varname,''',''var'')'])
    answer = questdlg( ...
        getString(message('SPLINES:resources:dlg_VariableExists', varname )), ...
        getString(message('SPLINES:resources:dlgTitle_VariableExists')),...
        getString(message('SPLINES:resources:uicontrol_No')),...
        getString(message('SPLINES:resources:uicontrol_Yes')),...
        getString(message('SPLINES:resources:uicontrol_No')));
    if isempty(answer) || strcmp(answer,getString(message('SPLINES:resources:uicontrol_No')))
        ok = 0;
    end
end
end  % okvar

function string = overlong(string)
%OVERLONG insert linebreak and percents appropriately into overlong lines

t = strfind(string,'%');
if ~isempty(t)
    z = '\n%% ';
    % separate the part before, to be appended later
    codestuff = string(1:t(1)-1);
    string = string(t(1):end);
else
    z = '...\n   ';
end
a = 0;
while length(string)-a>78
    t = strfind( string(a+(1:78)), ' ' );
    a = a + t(end);
    string = [string(1:a),z,string(a+1:end)];
end
if exist('codestuff','var') && ~isempty(codestuff)
    z = ':';
    if isequal(string(end),'.'),
        z = '';
    end
    string = [string,z,'\n',overlong(codestuff)];
end
end  % overlong

function parameters(hand)
% parameters    Change to the newly specified parameters

switch get(hand.method,'Value')
    case 1
        
        % (re?)-enable the edit pushbuttons
        set(hand.params(1,1:2),'Enable','on')
        
        % pick up what end condition was chosen.
        V = get(hand.endconds,'Value');
        lineud = get(hand.nameline,'UserData');
        lineud.endconds(1) = V;
        
        % for some of these, we need some data input before we can proceed
        set(hand.params(2:5,1:2),'Enable','off')
        if any([2 3 4 9]==V)
            % then we must turn on the clickable stuff, and ask for input
            set(hand.params(2:5,1:2),'Enable','on')
            
            switch V
                
                case {2,3}
                    if isequal(get(hand.params(1,1),'String'),...
                            getString(message('SPLINES:resources:uicontrol_x2ndDeriv'))),
                        toggle_ends(1,hand);
                    end
                    if isequal(get(hand.params(1,2),'String'),...
                            getString(message('SPLINES:resources:uicontrol_x2ndDeriv'))),
                        toggle_ends(2,hand);
                    end
                case 4
                    if isequal(get(hand.params(1,1),'String'),...
                            getString(message('SPLINES:resources:uicontrol_x1stDeriv'))),
                        toggle_ends(1,hand);
                    end
                    if isequal(get(hand.params(1,2),'String'),...
                            getString(message('SPLINES:resources:uicontrol_x1stDeriv'))),
                        toggle_ends(2,hand);
                    end
            end % switch V
        end
        
        % store endcondition details in lineud
        switch V
            case 1 %  'not-a-knot'
                lineud.endconds([2 3]) = [0 0];
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    'csapi(x,y);', ...
                    message( 'SPLINES:resources:BottomLine_SameAsTwoCommands', 'csape(x,y,''not-a-knot'')', 'spline(x,y)' ) );
            case {2,3} %  'clamped', 'complete'
                lineud.endconds([2 3]) = [1 1];
            case 4 %  'second'
                lineud.endconds([2 3]) = [2 2];
            case 5 %  'periodic'
                lineud.endconds([2 3]) = [0 0];
                lineud.bottom = iCreateBottomLine( hand.dbname, 'csape(x,y,''periodic'');', ...
                    message.empty() );
            case {6,7} %  'variational', 'natural'
                lineud.endconds([2 3]) = [2 2];
                lineud.valconds = [0 0];
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    'csape(x,y,''variational'');', ...
                    message( 'SPLINES:resources:BottomLine_csapeVariational', 'csape(x,[0,y,0],[2 2])', 'csaps(x,y,1)' ) );
            case 8 %  'Lagrange'
                lineud.endconds([2 3]) = [0 0];
                lineud.bottom = iCreateBottomLine( hand.dbname, ...
                    'csape(x,y);', ...
                    message( 'SPLINES:resources:BottomLine_csapeDefault' ) );
            case 9 %  'custom'
                % everything about it possibly changes with endcond input
        end %switch V
        
        set(hand.nameline,'UserData',lineud)
        
    case 2
        % all is done directly in get_approx
        
    case {3,4}
        % nothing so far
        
end %switch get(hand.method,'Value')

get_approx(hand)

end  % parameters

function iResetLabels(hand,answer)
% iResetLabels    Change Xlabel and/or Ylabel


fory = hand.Axes(1);
forx = hand.Axes(2);
tmp = get(forx,'Visible');
if tmp(2)=='f',
    forx = fory;
end

if isempty(answer) % ask for labels
    answer = inputdlg({getString(message('SPLINES:resources:dlg_GiveXlabel')), ...
        getString(message('SPLINES:resources:dlg_GiveYlabel'))}, ...
        getString(message('SPLINES:resources:dlgTitle_PleaseProvideLabels')), 1, ...
        {get(get(forx,'XLabel'),'String');
        get(get(fory,'YLabel'),'String')},'on');
end
if ~isempty(answer)
    set(get(forx,'XLabel'),'String', ...
        strrep(strrep(answer{1},'\',''),'_','\_'))
    set(get(fory,'YLabel'),'String', ...
        strrep(strrep(answer{2},'\',''),'_','\_'))
    
    % If the new y-label is the name of a function, it will be used in the error
    % calculation to provide the exact values.
    set(hand.dataline,'UserData', ...
        max(0,get_isf(answer{2},get(hand.dataline,'XData'))));
    temp = get(hand.viewmenu,'UserData');
    if temp(3),
        set_view(hand),
    end % if the error is on view, update it now
end
end  % iResetLabels

function segments = plotSegments(s)
% plotSegments   Plot a collection of segments
%
%        segments = plotSegments( s )
%
%   returns the appropriate sequences  SEGMENTS(1,:) and  SEGMENTS(2,:)
%   (containing the segment endpoints properly interspersed with NaN's) so that
%   PLOT(SEGMENTS(1,:),SEGMENTS(2,:)) plots the straight-line segment(s) with
%   endpoints  (S(1,:),S(2,:))  and  (S(d+1,:),S(d+2,:)) , with S of size
%   [2*d,:].

[twod,n] = size(s);
d = twod/2;
if d<2
    error(message('SPLINES:SPLINETOOL:wronginput'))
end
if d>2
    s = s([1 2 d+1 d+2],:);
end

tmp = [s; NaN(1,n)];
segments = [
    reshape(tmp([1 3 5],:),1,3*n)
    reshape(tmp([2 4 5],:),1,3*n)
    ];
end  % plotSegments

function set_bdisplay(breaks,hand)
%SET_BDISPLAY

if nargin==2
    lp1 = length(breaks);
    for j=1:2
        ylim = get(hand.Axes(j),'YLim');
        xy = plotSegments( [breaks; repmat(ylim(1),1,lp1); breaks; repmat(ylim(2),1,lp1)] );
        set(hand.breaks(j),'XData', xy(1,:),'YData', xy(2,:),'Visible','on', ...
            'UserData','on');
    end
    if ~any(get(hand.viewmenu,'UserData'))
        set(hand.breaks(2),'Visible','off')
    end
else % refresh the knot/break lines in second graph
    n = size(get(breaks.breaks(2),'YData'),2)/3;
    ylim = get(breaks.Axes(2),'YLim');
    set(breaks.breaks(2),'YData',...
        reshape([repmat(ylim(:),1,n);NaN(1,n)],1,3*n))
end
end  % set_bdisplay

function hand = set_current(hand)
%SET_CURRENT update the current setting according to the present value
%   of Value in list_names . If STRING is empty, start with the default.

names = get_names(get(hand.list_names,'String'));

if isempty(names)
    hand = iNewSpline(hand);
else % make the V-th guy the current one
    V = get(hand.list_names,'Value');
    name = names(V,:);
    view = name(1);
    name = name(6:end);
    listud = get(hand.list_names,'UserData');
    nameline = listud.handles(V);
    set(hand.currentline, ...
        'XData',get(nameline,'XData'), ...
        'YData',get(nameline,'YData'));
    hand.name = name;
    hand.dbname = deblank(name);
    if view=='v'
        set(hand.ask_show,'Value',1)
        set(hand.currentline,'Visible','on')
    else
        set(hand.ask_show,'Value',0)
        set(hand.currentline,'Visible','off')
    end
    % change to the former dataset if different from present one
    lineud = get(nameline,'UserData');
    temp = find(lineud.dc==get(hand.data_etc,'UserData'));
    if isempty(temp)
        xy = get(hand.highlightxy,'UserData');
        x = xy(1,:);
        y = xy(2,:);
        temp = 1;
    elseif temp<length(lineud.dc)
        x = get(hand.dataline,'XData');
        y = get(hand.dataline,'YData');
    end
    if exist('y','var')
        changes = get(hand.currentline,'UserData');
        for j=temp+1:length(lineud.dc)
            change = changes{lineud.dc(j)};
            rets = strfind(change, '\n');
            while length(rets)>1
                change(rets(end)+(-3:1))=[];
                rets(end) = [];
            end
            eval(change(strfind(change, '\n')+2:end));
        end
        set(hand.params(1,3),'Value',1)
        set_data(hand,x,y),
        iMarkDataPoint(hand)
        set(hand.data_etc,'UserData',lineud.dc(end))
    end
    hand.nameline = nameline;
    set(gcbf,'UserData',hand);
    set_view(hand);
    set_view_label(hand.name,hand);
end
end  % set_current

function set_data(hand,x,y)
%SET_DATA  (re)set the data

% If undo button is on, preserve current data in undoud
if isequal(get(hand.undo,'Enable'),'on')
    undoud.xy = [get(hand.dataline,'XData');
        get(hand.dataline,'YData')];
    set(hand.undo,'UserData',undoud)
end

set(hand.dataline,'XData',x(:),'YData',y(:))
hxlabel = get(hand.Axes(2),'XLabel');
if isempty(get(hxlabel,'UserData'))
    set(hxlabel,'UserData',1, ...
        'String', getString(message('SPLINES:resources:label_ModifiedData', get(hxlabel,'String'))) );
    if ~any(get(hand.viewmenu,'UserData'))
        set(get(hand.Axes(1),'XLabel'),'String', ...
            get(hxlabel,'String'))
    end
end
set(hand.params(1,3),'String',x(:))
set(hand.params(1,5),'String',y(:))
iMarkDataPoint(hand)

end  % set_data

function set_displays(hand)
%SET_DISPLAYS updates model, endconditions, bottomline, data/breaks, etc

%  extract all the line detail from nameline
lineud = get(hand.nameline,'UserData');

%  Set the bottom line:
set(hand.bottomlinetext, 'String',lineud.bottom)

%  reset the edit fields according to the current method
M = get(hand.method,'Value');
M0 = lineud.method;
% what should happen next depends on how we got here
tag = get(gcbo,'Tag');
if ~isempty(tag)&&(strcmp(tag,'list_names')||strcmp(tag,'Pushdel'))
    % either list_names or pushdel was clicked, hence  M  is actually the old
    % method and M0 is the new, hence we switch them now:
    M0 = M;
    M = lineud.method;
    % we are switching back to an old approx, hence must update the displays
    % concerning order and knots
    switch M
        case 2
            set(hand.order,'Value',max(1,fnbrk(lineud.cs,'order')/2-1))
            % This fails to recover the fact that smoothing order was 3 in case
            % the smoothing spline is of order < 6, e.g., if P was 0.
        case {3,4}
            set(hand.order,'Value',lineud.k)
            if get(hand.data_etc,'Value')==2 % must also update the knot display
                set(hand.params(1,4),'String',lineud.knots(:), ...
                    'Value',lineud.k+1)
                iMarkBreak(hand),
                set_bdisplay(lineud.knots,hand)
            end
    end
end
if M~=M0
    set(hand.method,'Value',M);
    set_edits(M,hand)
end

% fill editleft/rite etc appropriately
switch M
    case 1   %  Set the end conditions:
        
        % initialize 'String' and 'Userdata' for editleft and editrite to contain
        % slope and second derivative of the current spline, toggling these only
        % when the endconds is 2
        
        set(hand.endconds, 'Value',lineud.endconds(1) )
        
        for j=1:2
            if lineud.endconds(j+1)<1  % make edit and incrementers inactive
                enable = 'off';
            else
                enable = 'on';
            end
            set(hand.params(2,j), ...
                'Enable',enable, ...
                'String',lineud.ends(1,j),...
                'CreateFcn',num2str(lineud.ends(2,j)));
            set(hand.params(1,j), ...
                'String',getString(message('SPLINES:resources:uicontrol_x1stDeriv')));
            if lineud.endconds(j+1)==2,
                enable = toggle_ends(j,hand);
            end
            if enable(2) == 'n'
                set(hand.params(4,j),'Enable',enable, 'String',...
                    shortstr(abs(eval(get(hand.params(2,j),'String')))/10,1))
            else
                set(hand.params(4,j),'Enable',enable,'String',0)
            end
            set(hand.params([3 5],j),'Enable',enable)
        end
        
    case 2 % set parameter and tolerance
        set(hand.params(2,1),'String',shortstr(lineud.par,'',1))
        if ~get(hand.params(4,1),'Value')
            increm = min(lineud.par, 1-lineud.par)/10;
            if increm==0,
                increm = .01;
            end
            set(hand.params(4,1),'String',shortstr(increm,1))
        end
        set(hand.params(2,2),'String',shortstr(lineud.tol(1)))
        if ~get(hand.params(4,2),'Value')
            increm = lineud.tol(1)/10;
            if increm==0,
                increm = .01;
            end
            set(hand.params(4,2),'String',shortstr(increm,1))
        end
        
    case {3,4}
        for j=1:2
            set(hand.params(2,j),'String',lineud.ends(1,j),...
                'CreateFcn',num2str(lineud.ends(2,j)))
        end
        set(hand.params(4,1:2),'String',0)
        set(hand.params(1,1:2),'String',getString(message('SPLINES:resources:uicontrol_x1stDeriv')))
        
end %switch M

set(hand.figure,'Pointer','arrow')

end  % set_displays

function set_edits(M,hand)
%SET_EDITS  set up the fields for the viewing and editing of params and data

% Start by trying to define the labels in the popup in dependence on the
% gui's window size.

sitesvals =    sprintf('  %s',getString(message('SPLINES:resources:SitesAndValues')));
breakshead =   sprintf('  %s  ',getString(message('SPLINES:resources:Breaks')));
knotshead =    sprintf('  %s  ',getString(message('SPLINES:resources:Knots')));
% sitesweights = '  sites   and   error weights';
sitesweights = sprintf('               %s',getString(message('SPLINES:resources:ErrorWeights')));
%sitesjumps =   '  sites   and  roughness weight';
sitesjumps =    sprintf('  %s',getString(message('SPLINES:resources:RoughnessWeight')));

%  start with clean slate
set([hand.endconds; hand.partext(:); hand.params(1,:).'],'Visible','off')

set(hand.endtext,'String',getString(message('SPLINES:resources:label_Order')))

switch M
    case 1 % cubic spline interpolation
        
        set(hand.order, 'Visible','off')
        set([hand.endconds,hand.params(1,:),hand.partext(1,:)],'Visible','on')
        set(hand.endtext,'String',getString(message('SPLINES:resources:label_EndConditions')))
        
        set(hand.params(2,1:2),'Enable','on')
        %  also indicate that increment fields have not yet been edited,
        %  by setting their 'Value' to 0
        set(hand.params(4,1:2),'Value',0)
        
        % also choose the menu for data_etc and start it off with Value 1
        set(hand.data_etc, ...
            'Value',1, ...
            'String',{sitesvals; breakshead}, ...
            'TooltipString', getString(message('SPLINES:resources:tooltip_DataOrBreaks')))
        
    case 2 % smoothing spline
        
        set(hand.order,'String',{'4';'6'},'Visible','on')
        set(hand.partext(2,:),'Visible','on')
        set(hand.params(1:5,1:2),'Enable','on')
        %  clickables
        set(hand.params(2:5,1:2),'Enable','on')
        set(hand.params(4,1:2),'Value',0)
        
        % also choose the menu for data_etc and start it off with Value 1
        set(hand.data_etc, ...
            'Value',1, ...
            'String',{sitesvals; sitesweights; sitesjumps}, ...
            'TooltipString', getString(message('SPLINES:resources:tooltip_DataOrWeights')))
        
    case {3,4} %  least-squares approximation  and spline interpolation
        
        % start off with a clean slate concerning knots (unless we are returning
        % to a previous approximation)
        lineud = get(hand.nameline,'UserData');
        if isfield(lineud,'knots')&&~strcmp(get(gcbo,'Tag'),'list_names')
            set(hand.nameline,'UserData',rmfield(lineud,'knots'))
        end
        
        if isfield(lineud,'k'),
            k=lineud.k;
        else
            k=4;
            
        end
        set(hand.order,'String',get(hand.order,'UserData'),'Value',k,'Visible','on')
        set([hand.partext(1,:),hand.params(1,1:2)],'Visible','on')
        set(hand.params(2:5,1:2),'Enable','off')
        set(hand.params(1,1:2),'Enable','on')
        
        % also choose the menu for data_etc and start it off with Value 1
        if M==3
            set(hand.data_etc, 'Value',1, ...
                'String',{sitesvals;knotshead;sitesweights}, ...
                'TooltipString', getString(message('SPLINES:resources:tooltip_DataKnotsOrWeights')))
        else
            set(hand.data_etc, 'Value',1, ...
                'String',{sitesvals;knotshead}, ...
                'TooltipString', getString(message('SPLINES:resources:tooltip_DataOrKnots')))
        end
        
end % switch M

splinetool('data_etc',hand)

end  % set_edits

function set_legend( hand, ax, position, doTweakContextMenu )
%SET_LEGEND (re)generate the legend

if isequal(get(hand.tool(2),'Checked'),'off')
    return
end

% get the list of visible handles
names = get_names(get(hand.list_names,'String'));
listud = get(hand.list_names,'UserData');
handles = listud.handles;
% the following complication is needed when set_legend is used for printing
tmp = hand.currentline;
handles(get(hand.list_names,'Value')) = tmp(1);
listshown = find(names(:,1)=='v');
handles = handles(listshown);
names = ['data      ';names(listshown,6:end)];
% need to prevent Latex interpretation of underscore
names = strrep(cellstr(names),'_','\_');

hlegend = legend(ax,[hand.dataline;handles],names);
if nargin>2
    set(hlegend,'Position',position);
end

if nargin < 4 || doTweakContextMenu
    fix_legend_context_menu( hlegend, hand, ax )
end
end  % set_legend

function fix_legend_context_menu( hLegend, hand, ax )
% The legend gets created with a context menu. However this context menu has
% some features that have a destructive affect on SPLINETOOL. In this little
% function, we remove those features....
cmh = get( hLegend, 'UIContextMenu' );
if isempty( cmh )
    % If there is no context menu, then there is no need to remove anything
    % from it.
    return
end
% The children (menu entries) of the context menu are hidden so we need
% to get around that
h = allchild( cmh );
% Our actions are based on tags of items that appear in the context menu so
% we need to get all of those tags.
tags = get( h, 'Tag' );

% Delete the entries that cause bad things to happen
TAGS_TO_DELETE = {'scribe:legend:mcode', 'scribe:legend:propedit', 'scribe:legend:interpreter'};
tf = ismember( tags, TAGS_TO_DELETE );
delete( h(tf) );

% For the getString(message('SPLINES:resources:uicontrol_Delete')) item, we want to redirect the call to the SPLINETOOL legend
% toggle function
tf = ismember( tags, 'scribe:legend:delete' );
set( h(tf), 'Callback', @(s, e) set_tools( hand, 2, 'off' ) );

% For the 'Refresh' item, we want to redirect the callback to reset the
% properties of the legend, e.g., the colour and font.
tf = ismember( tags, 'scribe:legend:refresh' );
set( h(tf), 'Callback', @(s, e) set_legend( hand, ax ) );
end  % fix_legend_context_menu

function set_tools(hand,ip,onoff)
%SET_TOOLS
set(hand.tool(ip),'Checked',onoff)
switch ip
    case 1
        for j=1:2
            grid(hand.Axes(j),onoff)
        end
    case 2
        if length(onoff)==3
            set(hand.tool(2),'UserData',get(get(hand.Axes(1),'Legend'),'Position'));
            legend(hand.Axes(1),'off')
        else
            legpos = get(hand.tool(2),'UserData');
            if numel(legpos)==4
                set_legend(hand,hand.Axes(1),legpos)
            else
                set_legend(hand,hand.Axes(1))
            end
        end
end
end  % set_tools

function set_up_menu(cf)
%SET_UP_MENU

menu(cf,{getString(message('SPLINES:resources:dlg_ChooseData'));
    getString(message('SPLINES:resources:dlg_SPLINETOOL'))}, ...
    getString(message('SPLINES:resources:uicontrol_OwnData')), ...
    {'';getString(message('SPLINES:resources:dlg_Examples'))},...
    getString(message('SPLINES:resources:uicontrol_TitaniumData')), ...
    getString(message('SPLINES:resources:uicontrol_SmoothFunction')), ...
    getString(message('SPLINES:resources:uicontrol_TheFunction','sin(x) on [0 .. pi/2]')), ...
    getString(message('SPLINES:resources:uicontrol_CensusData')), ...
    getString(message('SPLINES:resources:uicontrol_RaceData')), ...
    getString(message('SPLINES:resources:uicontrol_Interpolant')));
end  % set_up_menu

function set_view(hand)
%SET_VIEW   update the view graph

viewud = get(hand.viewmenu,'UserData');

ip = find(viewud==1);
if ~isempty(ip)
    lineud = get(hand.nameline,'UserData');
    switch ip
        case 1
            xy = fnplt(lineud.dcs);
            set(hand.viewline,'XData',xy(1,:),'YData',xy(2,:))
        case 2
            xy = fnplt(lineud.ddcs);
            set(hand.viewline,'XData',xy(1,:),'YData',xy(2,:))
        case 3
            if get(hand.dataline,'UserData')
                xx = get(hand.nameline,'XData');
                set(hand.viewline,'XData', xx, ...
                    'YData', given(xx,hand)-get(hand.nameline,'YData'))
            else
                x = get(hand.dataline,'XData');
                y = get(hand.dataline,'YData');
                set(hand.viewline,'XData',x,'YData',y-fnval(lineud.cs,x));
            end
            % make a grey horizontal line in the lower plot representing
            % the zero line. The zero-line goes between the edges of the 
            % plot (between the x limits).
            tmp = get(hand.Axes(1),'XLim');
            set(hand.zeroline,'XData',tmp)
    end %switch ip
    if strcmp(get(hand.breaks(2),'UserData'),'on');
        set(hand.breaks(2),'Visible','off')
        set_bdisplay(hand),
        set(hand.breaks(2),'Visible','on')
    end
end
end  % set_view

function set_view_label(name,hand)
%SET_VIEW_LABEL update Ylabel in second axes to given name

if any(get(hand.viewmenu,'UserData'))
    hylabel = get(hand.Axes(2),'YLabel');
    tmp = get(hylabel,'String');
    tmp1 = strfind(tmp, ' ');
    set(hylabel,'String', ...
        [tmp(1:tmp1(end)),strrep(deblank(name),'_','\_')])
end
end  % set_view_label

function output = shortstr(varargin)
%SHORTSTR formatted string

if nargin<2 || isempty(varargin{2}),
    varargin{2} = '%-0.5g';
end
output = num2str(varargin{1:2});
if nargin>2 % if varargin{1} is close to 1, write it as 1 - something
    omv = 1-varargin{1};
    if omv<.001 && omv>0
        output = sprintf( '1 - %s', num2str(omv,varargin{2}) );
    end
end
end  % shortstr

function out = showtime
%SHOWTIME provide current time in the form the string hh:mm:ss

c = clock;
zm = '';
if c(5)<10,
    zm = '0';
end
ss = round(c(end));
zs = '';
if ss<10,
    zs = '0';
end

out = [num2str(c(4)),':',zm,num2str(c(5)),':',zs,num2str(ss)];
end  % showtime

function enable = toggle_ends(j,hand)
%TOGGLE_ENDS toggle between 1st and 2nd derivative value display

pushbutton = hand.params(1,j);
tmp = get(pushbutton,'String');
if tmp(1)=='1'
    deriv=2;
    set(pushbutton,'String',getString(message('SPLINES:resources:uicontrol_x2ndDeriv')));
else
    deriv=1;
    set(pushbutton,'String',getString(message('SPLINES:resources:uicontrol_x1stDeriv')));
end
h = hand.params(2,j);
enable = 'off';
if get(hand.method,'Value')==1
    V = get(hand.endconds,'Value');
    if(deriv==1&&(V==2||V==3))||(deriv==2&&V==4)||V==9
        enable = 'on';
    end
end
other = get(h,'CreateFcn');
ither = get(h,'String');
set(h,'String',other,'CreateFcn',ither,'Enable',enable)

end  % toggle_ends

function lineud = update(hand, part, lineud)
%UPDATE make sure that changes has the latest on PART

if nargin<3
    lineud = get(hand.nameline,'UserData');
end

changes = get(hand.currentline,'UserData');

switch part(1)
    
    case 'f'
        if ~isfield(lineud,'kc')||isempty(lineud.kc)
            lineud.kc(1) = addchange(hand.currentline, ...
                strrep(lineud.bottom(2:end),'%','%%'));
        elseif ~isempty(strfind(changes{lineud.kc(end)}, '\nknots ='))||...
                ~isempty(strfind(changes{lineud.kc(end)}, '\nknots('))
            lineud.kc(end+1) = addchange(hand.currentline, ...
                strrep(lineud.bottom(2:end),'%','%%'));
        end
        
    case 'k'
        if ~isfield(lineud,'kc')||isempty(lineud.kc)
            [lineud.kc(1),changes] = addchange(hand.currentline, ...
                strrep(lineud.bottom(2:end),'%','%%'));
        end
        if isempty(strfind(changes{lineud.kc(end)}, '\nknots ='))&&...
                isempty(strfind(changes{lineud.kc(end)}, '\nknots('))
            lineud.kc(end+1) = addchange(hand.currentline, ...
                ['knots = fnbrk(', ...
                lineud.bottom(2:(strfind(lineud.bottom(1:13), ' =')-1)), ...
                ',''knots''); %% ',...
                getString(message('SPLINES:resources:commnad_ExtractKnots'))]);
        end
        
    case 'w'
    otherwise
        error(message('SPLINES:SPLINETOOL:impossible'))
end
end  % update

function iViewLowerPlot(clicked, ip, hand)
%VIEW

set(hand.zeroline,'Visible','off')
viewud = get(hand.viewmenu,'UserData');
Axes1 = hand.Axes(1);
Axes2 = hand.Axes(2);
if viewud(ip)==1  % turn off the view
    set(clicked,'Checked','off')
    set(get(Axes1,'XLabel'),'String',get(get(Axes2,'XLabel'),'String'))
    set(Axes1,'XTickLabel', get(Axes2,'XTickLabel'))
    set([Axes2;allchild(Axes2)],'Visible','off')
    viewud(ip)=0;
else
    set(clicked,'Checked','on')
    otherv = find(viewud==1);
    if isempty(otherv) % turn on the view
        set([Axes2,hand.viewline],'Visible','on')
        set(get(Axes1,'XLabel'),'String',[])
        set(Axes1,'XTickLabel',[])
    else  % toggle the label currently shown
        viewud([ip,otherv])=[1 0];
        set(hand.view(otherv),'Checked','off')
    end
    
    % viewud(ip)=1; ufname = strrep(deblank(hand.dbname),'_','\_');
    viewud(ip)=1;
    ufname = strrep(hand.dbname,'_','\_');
    switch ip
        case 1
            set(get(Axes2,'YLabel'),'String', getString(message('SPLINES:resources:label_1stDerivOf', ufname)) );
        case 2
            set(get(Axes2,'YLabel'),'String', getString(message('SPLINES:resources:label_2ndDerivOf', ufname )) );
        case 3
            set(get(Axes2,'YLabel'),'String', getString(message('SPLINES:resources:label_ErrorIn', ufname )) );
            set(hand.zeroline,'Visible','on')
    end %switch ip
end %if viewud(ip)==1
set(hand.viewmenu,'UserData',viewud);
set_view(hand)

end  % iViewLowerPlot

function helpOnCurvefitToolbox( ~, ~ )
% helpOnCurvefitToolbox -- Display help on Curve Fitting Toolbox
%   helpOnCurvefitToolbox( src, evt )
doc curvefit
end  % helpOnCurvefitToolbox

function warningCleanup = warningOff( id )
% Turn off warnings and create a cleanup function to return them to the original
% state.
warningState = warning( 'off', id );
warningCleanup = onCleanup( @() warning( warningState ) );
end  % warningOff

function iAssignInBase( name, value )
% iAssignInBase   Assign a variable to the base workspace
assignin( 'base', name, value );
end  % iAssignInBase

function iDoCallback( handle )
% iDoCallback   Perform the callback operation on a handle
aFunction = get( handle, 'Callback' );
if isa( aFunction, 'function_handle' );
    aFunction();
else
    % assume that the callback is a string
    eval( aFunction );
end
end  % iDoCallback

function iDoAddItem(hand,hc)
switch get(hand.data_etc,'Value')
    case 1
        [xx,yy] = ask_for_add(hand);
        x = get(hand.dataline,'XData');
        if xx<x(1)||xx>x(end)
            warndlg(getString(message('SPLINES:resources:dlg_ExteriorSites')), ...
                getString(message('SPLINES:resources:dlgTitle_ApproximationChange')),'modal')
        elseif get(hand.method,'Value')==4 && any(x==xx)
            warndlg(getString(message('SPLINES:resources:dlg_RepeatedSites')), ...
                getString(message('SPLINES:resources:dlgTitle_RepeatedDataSites')), 'modal');
        else
            set(hand.undo,'Enable','on')
            insert_and_mark(x,get(hand.dataline,'YData'),xx,yy,hand)
            undoud = get(hand.undo,'UserData');
            undoud.lineud = get(hand.nameline,'UserData');
            set(hand.undo,'UserData',undoud);
            
            get_approx(hand)
        end
        if isequal(get(hand.undo,'Enable'),'off')
            V = get(hand.params(1,3),'Value');
            set(hand.params(2,3),'String',x(V))
            if isequal(get(hand.params(2,5),'Visible'),'on')
                y = get(hand.dataline,'YData');
                set(hand.params(2,5),'String',y(V))
            end
        end
        
    case 2
        switch get(hand.method,'Value')
            case 3
                xx = ask_for_add(hand);
                lineud = get(hand.nameline,'UserData');
                [lineud.knots,i] = sort([lineud.knots,xx]);
                placed = find(i==length(lineud.knots));
                if placed==1||placed==length(lineud.knots)
                    warndlg(getString(message('SPLINES:resources:dlg_NonInteriorKnots')),...
                        getString(message('SPLINES:resources:dlgTitle_AddKnots')),'modal')
                    lineud.knots(placed)=[];
                    set(hand.nameline,'UserData',lineud)
                    set(hand.params(2,4),'String', ...
                        lineud.knots(get(hand.params(1,4),'Value')))
                    
                else
                    set(hand.params(1,4),'String',lineud.knots(:),'Value', placed)
                    lineud = update(hand,'knots',lineud);
                    lineud.kc(end+1) = ...
                        addchange(hc,sprintf('knots = sort([knots,%s]); %% %s',num2str(xx,15),...
                        getString(message('SPLINES:resources:AddAKnot'))));
                    set(hand.nameline,'UserData',lineud)
                    % update knots display
                    set(hand.buttonm,'Visible','on')
                    set(hand.params(4,4), 'String',...
                        (lineud.knots(end)-lineud.knots(1))/(10*length(lineud.knots)))
                    iMarkBreak(hand),
                    set_bdisplay(lineud.knots,hand)
                    
                    get_approx(hand)
                end
        end %switch get(hand.method,'Value')
    case 3
        
end % switch get(hand.data_etc,'Value')
end % iDoAddItem

function iDoAlign(hand)
% make sure the left and right data list are aligned
% at present, this serves no function, but sits here in case clicking
% anywhere on a list box activates a callback
tag = get(gcbo,'Tag');
if tag(5)=='l'
    j=3;
else
    j=5;
end
set(hand.params(1,8-j),'Value',get(hand.params(1,j),'Value'))

end  % iDoAlign

function iDoAxesClick(hand)
% action when the axes is clicked

% protect against clicks on Print Figure window:
if isempty(hand),
    return
end
% only react here to LEFT clicks
tmp = get(hand.figure,'SelectionType');
if tmp(1)=='n'
    
    % get the location of the latest click in data coordinates:
    clickp = get(hand.Axes(1),'CurrentPoint');
    
    switch get(hand.data_etc,'Value')
        case {1,3} % highlight the nearest data point
            highlightn(clickp,hand)
            
        case 2
            switch get(hand.method,'Value')
                case {1,3,4}
                    
                    % find the nearest break
                    breaks = str2num(get(hand.params(1,4),'String')); %#ok<ST2NM> breaks is a vector
                    [~,V]=min(abs(breaks(:)-repmat(clickp(1),length(breaks),1)));
                    if get(hand.params(1,4),'Value')~=V
                        set(hand.params(1,4),'Value',V),
                        iMarkBreak(hand)
                    end
                case 2
                    highlightn(clickp,hand)
                    
            end %switch get(hand.method,'Value')
            
    end %switch get(hand.data_etc,'Value')
end % if tmp(1)=='n'
end  % iDoAxesClick

function iDoChangeName(hand,hc)
% change the name of the current spline

names = get_names(get(hand.list_names,'String'));
V = get(hand.list_names,'Value');
oldname = names(V,:);
oldname = deblank(oldname(6:end));
name = '';
while isempty(name)
    answer = inputdlg(...
        sprintf('%s\n',getString(message('SPLINES:resources:dlg_GiveAVariableName'))),...
        getString(message('SPLINES:resources:dlgTitle_NewName')), 1,...
        {oldname});
    if isempty(answer)||strcmp(answer{:},oldname)
        return
    end
    name = full_name(answer{1});
end
hand.name = name;
hand.dbname = deblank(name);
set(hand.figure,'UserData',hand)
if get(hand.ask_show,'Value')==1
    prefix = 'v ||';
else
    prefix = '  ||';
end
names(V,:) = sprintf( '%s %s', prefix, name );
set(hand.list_names,'String',{names})
lineud = update(hand,'fit');
if isfield(lineud,'kc')
    lineud.kc(end+1) = addchange(hc, ...
        [hand.dbname,' = ',deblank(oldname),'; %% ',getString(message('SPLINES:resources:ChangeName'))]);
end
lineud.bottom = [' ',hand.dbname, ...
    lineud.bottom(strfind(lineud.bottom(1:14), ' ='):end)];
set(hand.bottomlinetext, 'String',lineud.bottom)
set(hand.nameline,'Tag',name,'UserData',lineud)
set_view_label(name,hand)
if names(V,1)=='v'
    set_legend(hand,hand.Axes(1),get(get(hand.Axes(1),'Legend'),'Position'))
end
end  % iDoChangeName

function iDoChangeOrder(hand,hc)
% call_back from the order selector in approximation field

M = get(hand.method,'Value');
switch M
    
    case 2 % we are smoothing, hence now must change the edit fields
        set_edits(2,hand)
        
    case {3,4}
        lineud = update(hand,'knots');
        lineud.k = get(hand.order,'Value');
        if M==3  % we are doing least-squares
            lineud.knots = augknt(lineud.knots,lineud.k);
            lineud.kc(end+1) = iAddCommentedChange( hc, ...
                sprintf( 'knots = augknt(knots,%s);', num2str(lineud.k) ), ...
                message( 'SPLINES:resources:comment_ChangeOrder' ) );
        else     % we are doing interpolation
            [lineud.knots,lineud.k] = aptknt(get(hand.dataline,'XData'),lineud.k);
        end
        if get(hand.data_etc,'Value')==2  %  need to update the knot display
            set(hand.params(1,4),'String',lineud.knots(:),'Value',1+lineud.k)
            iMarkBreak(hand),
            set_bdisplay(lineud.knots,hand)
        end
        set(hand.nameline,'UserData',lineud)
        
end %switch M

get_approx(hand)

end  % iDoChangeOrder

function iDoTerminate()
% terminate splinetool

answer = questdlg(...
    sprintf('%s\n%s',getString(message('SPLINES:resources:dlg_Close')), ...
    getString(message('SPLINES:resources:dlg_LoseUnsavedData'))), ...
    getString(message('SPLINES:resources:dlgTitle_CloseTool')),...
    getString(message('SPLINES:resources:uicontrol_OK')),...
    getString(message('SPLINES:resources:uicontrol_Cancel')),...
    getString(message('SPLINES:resources:uicontrol_OK')));
if isempty(answer) || strcmp(answer,getString(message('SPLINES:resources:uicontrol_Cancel')))
    return
end
iDoDeleteSplinetool();
end  % iDoTerminate

function iDoDeleteSplinetool()
% close splinetool without further ado

delete(findobj('Tag','Spline Tool Example Message Box'))
delete(findobj(allchild(0),'Name',getString(message('SPLINES:resources:SplineTool'))))

end  % iDoDeleteSplinetool

function iDoDataEtcetera(hand)
% callback from 'data_etc' to set up for present edit choice

% start clean
set([reshape(hand.params(:,3:5),15,1); hand.buttonm; hand.piecem; ...
    hand.piecetext; ...
    hand.highlightxy;hand.highlightb;hand.breaks(:);hand.rep_knot(:); ...
    hand.add_item(:);hand.del_item(:)], 'Visible','off')
set(hand.breaks(:),'UserData','off')
set(hand.undo,'Enable','off')

switch get(hand.data_etc,'Value')
    case 1  % turn on the data display
        set(hand.add_item,'Label',getString(message('SPLINES:resources:menu_AddPoint')),'Visible','on')
        set(hand.del_item,'Label',getString(message('SPLINES:resources:menu_DeletePoint')),'Visible','on')
        set(get(hand.Axes(1),'Children'),'UIContextMenu',hand.context)
        x = get(hand.dataline,'XData');
        set(hand.params(1,3),'String',x, ...
            'Visible','on', ...
            'BackgroundColor',[1 1 1], ...
            'Callback','splinetool ''highlightxy''', ...
            'TooltipString', ...
            getString(message('SPLINES:resources:tooltip_MarkAPoint')))
        set(hand.params(2,3),'String',x(1),'Visible','on')
        set(hand.params([3 5],3), 'Visible','on')
        set(hand.params(4,3),'Visible','on','Value',0)
        if ~get(hand.params(4,3),'Value')
            set(hand.params(4,3),'String',(x(end)-x(1))/(10*length(x)))
        end
        
        y = get(hand.dataline,'YData');
        if get(hand.dataline,'UserData')
            set(hand.params(1,5),'String',y,'Visible','on', ...
                'BackgroundColor',.9*[1 1 1], ...
                'Callback','splinetool ''highlightxy''', ...
                'TooltipString','')
        else
            set(hand.params(1,5),'String',y, 'Visible','on', ...
                'BackgroundColor',[1 1 1], ...
                'Callback','splinetool ''highlightxy''', ...
                'TooltipString', ...
                getString(message('SPLINES:resources:tooltip_MarkAPoint')))
            set(hand.params(2,5),'String',y(1),'Visible','on')
            set(hand.params([3 5],5), 'Visible','on')
            set(hand.params(4,5),'Visible','on','Value',0)
            if ~get(hand.params(4,5),'Value')
                set(hand.params(4,5),'String',(max(y)-min(y))/(10*length(y)))
            end
        end %if get(hand.dataline,'Userdata')
        set(hand.highlightxy,'Visible','on')
        iMarkDataPoint(hand) % also sets the editclkr field
        
    case 2
        M = get(hand.method,'Value');
        switch M
            case 1   % turn on the breaks display on the middle
                set(get(hand.Axes(1),'Children'),'UIContextMenu',[])
                lineud = get(hand.nameline,'UserData');
                breaks = fnbrk(lineud.cs,'breaks');
                set(hand.params(1,4),'String',breaks(:), ...
                    'Visible','on', ...
                    'TooltipString',getString(message('SPLINES:resources:tooltip_MarkABreak')), ...
                    'Callback','splinetool ''highlightb''')
                set_bdisplay(breaks,hand),
                iMarkBreak(hand)
                set(hand.highlightb,'Visible','on')
                
            case 2   % turn on the sites/weight display
                set(get(hand.Axes(1),'Children'),'UIContextMenu',[])
                set(hand.params(1,3),'String',get(hand.dataline,'XData'), ...
                    'Visible','on', ...
                    'BackgroundColor',.9*[1 1 1], ...
                    'Callback','splinetool ''highlightxy''', ...
                    'TooltipString','')
                lineud = get(hand.nameline,'UserData');
                set(hand.params(1,5),'String',lineud.w(:), ...
                    'Visible','on', ...
                    'Enable','on', ...
                    'BackgroundColor',[1 1 1], ...
                    'Callback','splinetool ''highlightw''', ...
                    'TooltipString',getString(message('SPLINES:resources:tooltip_MarkAWeight')))
                set(hand.params(2,5),'String',lineud.w(1),'Visible','on')
                set([hand.highlightxy;hand.params([3 5],5)], ...
                    'Visible','on')
                set(hand.params(4,5),'Visible','on','Value',0,'String',.1)
                
                iMarkDataPoint(hand)
                
            case {3,4}  % turn on the knots display in the middle
                lineud = get(hand.nameline,'UserData');
                knots = fnbrk(lineud.cs,'knots');
                npk = length(knots);
                set(hand.params(1,4),'String',knots(:), ...
                    'Visible','on', ...
                    'TooltipString', ...
                    getString(message('SPLINES:resources:tooltip_MarkAKnot')),...
                    'Callback','splinetool ''highlightb''', ...
                    'Value',1+lineud.k)
                iMarkBreak(hand),
                set_bdisplay(knots,hand)
                if M==3
                    set(get(hand.Axes(1),'Children'),'UIContextMenu',hand.context)
                    set(hand.add_item,'Label',getString(message('SPLINES:resources:menu_AddKnot')),'Visible','on')
                    set(hand.del_item,'Label',getString(message('SPLINES:resources:menu_DeleteKnot')),'Visible','on')
                    set(hand.rep_knot,'Visible','on')
                    % show the newknt button and piecem window
                    set([hand.piecem,hand.piecetext],'Visible','on')
                    if npk>2*lineud.k %  if there are interior knots ...
                        set(hand.buttonm,'Visible','on')
                    end
                end
                set([hand.highlightb;hand.params([2,3,5],4)],'Visible','on')
                set(hand.params(4,4),'Visible','on','Value',0)
                set(hand.params(4,4), ...
                    'String',(knots(end)-knots(1))/(10*length(knots)))
                
        end %switch M
        
    case 3 %  so far, these concern a weight display
        
        set(get(hand.Axes(1),'Children'),'UIContextMenu',[])
        set(hand.params(1,3),'String',get(hand.dataline,'XData'), ...
            'Visible','on', ...
            'BackgroundColor',.9*[1 1 1], ...
            'Callback','splinetool ''highlightxy''', ...
            'TooltipString','')
        lineud = get(hand.nameline,'UserData');
        set([hand.highlightxy; hand.params([2 3 5],5)], 'Visible','on')
        set(hand.params(4,5),'Visible','on','Value',0,'String',.1)
        
        switch get(hand.method,'Value')
            
            case 2 % turn on the sites/jump in weights display
                tols = lineud.tol;
                if length(tols)==1
                    nx = length(get(hand.dataline,'XData'));
                    tols = [tols,ones(1,nx-1)];
                    lineud.tol = tols;
                    lineud.tc(1) = iAddCommentedChange( hand.currentline, ...
                        sprintf( 'dlam = [1,zeros(1,%s)];', num2str(nx-2) ), ...
                        message( 'SPLINES:resources:comment_UniformRoughnessWeight' ) );
                    set(hand.nameline,'UserData',lineud)
                end
                tols = [tols(2),diff(tols(2:end)),NaN];
                
                set(hand.params(1,5),'String',tols, ...
                    'Visible','on', ...
                    'Enable','on', ...
                    'BackgroundColor',[1 1 1], ...
                    'Callback','splinetool ''highlightw''', ...
                    'TooltipString', ...
                    getString(message('SPLINES:resources:tooltip_MarkAWeightJump')))
                
            case 3 % turn on the sites/weight display
                set(hand.params(1,5),'String',lineud.w(:), ...
                    'Visible','on', ...
                    'Enable','on', ...
                    'BackgroundColor',[1 1 1], ...
                    'Callback','splinetool ''highlightw''', ...
                    'TooltipString',getString(message('SPLINES:resources:tooltip_MarkAWeight')))
        end %switch get(hand.method,'Value')
        
        iMarkDataPoint(hand) % also sets the editclkr field
        
end % switch get(hand.data_etc,'Value')
end  % iDoDataEtcetera

function iDoDeleteSpline(hand)
% delete the current spline

% the Value in list_names points to the current spline in that list
listud = get(hand.list_names,'UserData');
V = get(hand.list_names,'Value');
names = get_names(get(hand.list_names,'String'));

% If our user is deleting the last spline, warn them that we are going to create
% a new one for them.
if size( names, 1 ) <= 1
    answer = questdlg( sprintf( '%s\n%s',...
        getString(message('SPLINES:resources:dlg_DeleteLastSpline')), ...
        getString(message('SPLINES:resources:dlg_CreateDefaultSpline')) ), ...
        getString(message('SPLINES:resources:dlgTitle_DeleteSpline')),...
        getString(message('SPLINES:resources:uicontrol_OK')),...
        getString(message('SPLINES:resources:uicontrol_Cancel')),...
        getString(message('SPLINES:resources:uicontrol_OK')) );
    if isempty(answer) || strcmp(answer,getString(message('SPLINES:resources:uicontrol_Cancel')))
        return
    end
end
delete(listud.handles(V))
listud.length = listud.length-1;
listud.handles(V) = [];
set(hand.list_names, ...
    'String',{names([1:V-1 V+1:end],:)}, ...
    'Value',max(1,min(V,listud.length)), ...
    'UserData',listud);
hand = set_current(hand);
set_displays(hand)
set_legend(hand,hand.Axes(1))

end  % iDoDeleteSpline

function iDoDeleteItem(hand,hc)
% delete the current item

switch get(hand.data_etc,'Value')
    case 1
        V = get(hand.params(1,3),'Value');
        x = get(hand.dataline,'XData');
        if V==1||V==length(x)
            warndlg(getString(message('SPLINES:resources:dlg_ExtremeDataPoint')),...
                getString(message('SPLINES:resources:dlgTitle_Data')))
            return
        end %if V==1||V==length(x)
        
        y = get(hand.dataline,'YData');
        x(V) = [];
        y(V) = [];
        
        % record the commands that effect the change:
        sV = num2str(V);
        cindex = addchange(hc, ['x(',sV,') = []; y(', ...
            sV,') = []; %% you deleted a data point']);
        
        set(hand.params(1,3),'Value',min(V,length(x)))
        set(hand.params(1,5),'Value',min(V,length(y)));
        set(hand.undo,'Enable','on')
        set_data(hand,x,y)
        undoud = get(hand.undo,'UserData');
        undoud.lineud = get(hand.nameline,'UserData');
        set(hand.undo,'UserData',undoud);
        lineud = get(hand.nameline,'UserData');
        % update the weights, if any, and update data field
        if isfield(lineud,'w')
            if length(lineud.wc)==1 % we are using a standard weight;
                % simply let method 2 or 3 start the weight again
                lineud = rmfield(lineud,'w');
                lineud.wc=[];
            else % we delete the corresponding weight
                lineud.w(V) = [];
                lineud.wc(end+1) = addchange(hc,['weights(',sV,')=[];', ...
                    getString(message('SPLINES:resources:command_DeleteErrorWeight'))]);
            end
        end
        if isfield(lineud,'tc')  % we have roughness weights in place
            temp = diff(lineud.tol(V:V+1));
            if temp
                lineud.tol(V) = temp/2;
            end
            lineud.tol(V+1) = [];
            
            lineud.tc(end+1) = iAddCommentedChange( hc, ...
                iCodeToDistributeJumpInRoughness( sV ), ...
                message( 'SPLINES:resources:comment_DistributeJumpInRoughness' ) );
        end
        if lineud.method==4
            lineud = rmfield(lineud,'knots');
            lineud.kc = [];
        end
        lineud.dc(end+1) = cindex;
        set(hand.nameline,'UserData',lineud);
        set(hand.data_etc,'UserData',cindex);
        get_approx(hand)
        set(hand.highlightxy,'XData',[get(hand.highlightxy,'XData'),x(V)], ...
            'YData',[get(hand.highlightxy,'YData'),y(V)])
    case 2
        V = get(hand.params(1,4),'Value');
        lineud = get(hand.nameline,'UserData');
        npk = length(lineud.knots);
        if V<=lineud.k||V>npk-lineud.k
            warndlg(getString(message('SPLINES:resources:dlg_CannotDeleteAnEndKnot')), ...
                getString(message('SPLINES:resources:dlgTitle_DeleteKnots')))
        else
            lineud.knots(V)=[];
            lineud = update(hand,'knots',lineud);
            lineud.kc(end+1) = addchange(hc, ['knots(',num2str(V),') = [];',...
                getString(message('SPLINES:resources:command_YouDeletedAKnot'))]);
            
            tmp = get(hand.params(1,4),'String');
            tmp(V,:)=[];
            set(hand.params(1,4),'String',tmp)
            set(hand.params(1,4),'Value',min(V,npk-lineud.k));
            set(hand.nameline,'UserData',lineud)
            if length(lineud.knots)<=2*lineud.k
                set(hand.buttonm,'Visible','off')
            end
            set(hand.params(4,4), 'String',...
                (lineud.knots(end)-lineud.knots(1))/(10*length(lineud.knots)))
            iMarkBreak(hand),
            set_bdisplay(lineud.knots,hand)
            
            get_approx(hand)
            
        end
        
end % switch get(hand.data_etc,'Value')
end  % iDoDeleteItem

function iDoExportData(hand)
curtag = get(hand.dataline,'Tag'); % used in serializing exported data
xname = ['x',curtag];
yname = ['y',curtag];
accepted = 0;
while ~accepted
    answer = inputdlg({...
        sprintf('%s:',getString(message('SPLINES:resources:dlg_SaveSites'))),...
        sprintf('%s:',getString(message('SPLINES:resources:dlg_SaveValues')))},...
        getString(message('SPLINES:resources:dlgTitle_SaveToWorkspace')), 1,{xname;yname});
    if ~isempty(answer)
        okx = okvar(answer{1});
        oky = okvar(answer{2});
        if isequal(xname,answer{1}) % increment the counter kept in tag
            set(hand.dataline,'Tag', num2str( str2double( curtag )+1 ) );
        end
        if okx,
            xname = answer{1};
        end
        if oky,
            yname = answer{2};
        end
        if okx&&oky,
            accepted = 1;
        end
    else
        break
    end
end

if accepted
    iAssignInBase( xname, get(hand.dataline','XData') );
    iAssignInBase( yname, get(hand.dataline','YData') );
    fprintf( '%s\n',getString(message('SPLINES:resources:dlg_SaveToWorkspace', ...
        xname, yname)) )
end
end  % iDoExportData

function iDoExportSpline(hand)
namewob = hand.dbname;
accepted = 0;
while ~accepted
    answer = inputdlg(...
        sprintf('%s:',getString(message('SPLINES:resources:dlg_SaveSplines'))),...
        getString(message('SPLINES:resources:dlgTitle_SaveToWorkspace')),1,{namewob});
    if isempty(answer),
        return,
    end
    if okvar(answer{1}),
        namewob = answer{1};
        accepted = 1;
    end
end

lineud = get(hand.nameline,'UserData');
iAssignInBase( answer{1}, lineud.cs )
fprintf( sprintf('%s\n',getString(message('SPLINES:resources:CreateVariableInWorkspace', answer{1}))) )

end  % iDoExportSpline

function iDoGraphicalInputMove(hand)
pt = get(gca,'CurrentPoint');
xlim = get(gca,'XLim');
if xlim(1)<=pt(1,1) && pt(1,1)<=xlim(2)
    set(hand(1),'String',pt(1,1))
    if length(hand)>1,
        set(hand(2),'String',pt(1,2)),
    end
end
end  % iDoGraphicalInputMove

function iDoGraphicalInputDone()
set(gcbf,'WindowButtonMotionFcn','','WindowButtonDownFcn','','Pointer','arrow');
end  % iDoGraphicalInputDone

function abouttext = iAboutText()

v = ver('curvefit');
[relYear,~,~] = datevec(v.Date);
abouttext = {
    sprintf( '%s %s', v.Name, v.Version )
    sprintf( 'Copyright 1987-%d The MathWorks, Inc.', relYear )
    };
end  % iAboutText

function iDoHelp( term )
titlestring = getString(message('SPLINES:resources:dlgTitle_Explanation',term ));
abouttext = iAboutText();

switch term
    
    case 'about the GUI'
        mess =...
            { sprintf('\n%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s',...
            getString(message('SPLINES:resources:term_AboutLine1')),...
            getString(message('SPLINES:resources:term_AboutLine2')),...
            getString(message('SPLINES:resources:term_AboutLine3')),...
            getString(message('SPLINES:resources:term_AboutLine4')),...
            getString(message('SPLINES:resources:term_AboutLine5')),...
            getString(message('SPLINES:resources:term_AboutLine6')),...
            getString(message('SPLINES:resources:term_AboutLine7')),...
            getString(message('SPLINES:resources:term_AboutLine8'))) };
        
    case 'cubic spline interpolation'
        mess = concat(spterms(term), ...
            {sprintf('\n%s\n\n%s',...
            getString(message('SPLINES:resources:term_CubicSmoothingInterpolantLine1')),...
            getString(message('SPLINES:resources:term_CubicSmoothingInterpolantLine2')))});
        
    case 'endconditions' % end conditions
        mess = getString( message( 'SPLINES:resources:term_EndConditionLine1',...
            'x = linspace(0,2*pi,31))), y = cos' ) );
        
    case 'Customized'
        mess = getString(message('SPLINES:resources:term_Customized'));
        
    case 'least squares'
        mess = concat(spterms(term), ...
            {sprintf('\n%s',getString(message('SPLINES:resources:term_LeastSquaresLine4')))});
        
    case 'cubic smoothing spline'
        mess = concat(spterms(term), ...
            {sprintf('\n%s\n\n%s',...
            getString(message('SPLINES:resources:term_CubicSmoothingSplineLine5', 'integral (y(t) - s(t))^2 dt' )),...
            getString(message('SPLINES:resources:term_CubicSmoothingSplineLine6')))});
        
    case 'quintic smoothing spline'
        mess = {sprintf('%s\n\n%s',...
            getString(message('SPLINES:resources:term_QuinticSmoothingSplineLine3')),...
            getString(message('SPLINES:resources:term_QuinticSmoothingSplineLine4')))};
        
    case 'weight in roughness measure'
        mess = {
            getString(message('SPLINES:resources:term_WeightRoughnessMeasureLine1')), ...
            getString(message('SPLINES:resources:term_WeightRoughnessMeasureLine4','x_{i-1} .. x_i)')),...
            '', ...
            getString(message('SPLINES:resources:term_WeightRoughnessMeasureLine5')),...
            '', ...
            getString(message('SPLINES:resources:term_WeightRoughnessMeasureLine6'))
            };
        
    case 'spline'
        mess = concat(spterms(term), ...
            {sprintf('\n%s\n\n%s',...
            getString(message('SPLINES:resources:term_SplineLine1')),...
            getString(message('SPLINES:resources:term_SplineLine2')))});
        
    case 'about'
        titlestring = getString(message('SPLINES:resources:dlgTitle_About'));
        mess = abouttext;
        
    otherwise
        mess = spterms(term);
end %switch y

msgbox(mess,titlestring)

end  % iDoHelp

function iDoMarkWeight(hand)
% mark a weight (and the corresponding point)

V = get(hand.params(1,5),'Value');
set(hand.params(1,3),'Value',V);
iMarkDataPoint(hand)
tmp = get(hand.params(1,5),'String');
set(hand.params(2,5),'String',tmp(V,:))

end  % iDoMarkWeight

function iDoIncrement(hand)
% convert expression to a value, checking validity

tag = get(gcbo,'Tag');
j = find('telmr'==tag(end));
output = iEvaluateEditField( hand.params(4,j), 0 );
if ischar(output)
    set(hand.params(4,j),'String', ...
        shortstr(abs(str2double(get(hand.params(2,j),'String')))/10,1))
else
    set(hand.params(4,j),'String',shortstr(output,1),'Value',1)
end
end  % iDoIncrement

function iDoMakeCurrent(hand)
hand = set_current(hand);
set_displays(hand)
% the next statement is a quick fix to ensure that making another
% approximation current will leave the legend in its current place.
set(hand.tool(2),'UserData',get(get(hand.Axes(1),'Legend'),'Position'));
for j=1:2,
    set_tools(hand,j,get(hand.tool(j),'Checked')),
end
end  % iDoMakeCurrent

function iDoMoveItem(hand)
% iDoMoveItem   Move an item to the position suggested by its editbox

switch get(hand.data_etc,'Value')
    case 1
        move_point(hand)
    case 2
        switch get(hand.method,'Value')
            case 2
                change_weight(hand)
            case {3,4}
                if move_knot(hand)
                    get_approx(hand)
                end
        end % switch get(hand.method,'Value')
    case 3
        switch get(hand.method,'Value')
            case 2
                get_approx(hand)
            case 3
                change_weight(hand)
        end %switch get(hand.method,'Value')
end % switch get(hand.data_etc,'Value')
end  % iDoMoveItem

function iDoPlusMinus(hand)
% iDoPlusMinus   One of the increment/decrement guys has been clicked

handle = gcbo;
tag = get(handle,'Tag');

% find out whether to increment or decrement, ...
if strncmp( tag, 'plus', 4 )
    fcn = @plus;
elseif strncmp( tag, 'minus', 5 )
    fcn = @minus;
else
    warning( 'SPLINES:SPLINETOOL:NeitherIncrementOrDecrement', ...
        'The button clicked on is neither increment or decrement. Assuming increment.' );
    fcn = @plus;
end

% ... then change the numerical value of its edit field accordingly ...
j = find('telmr'==tag(end));
editValue      = str2double( get( hand.params(2,j), 'String' ) );
incrementValue = str2double( get( hand.params(4,j), 'String' ) );
newValue = fcn( editValue, incrementValue );

% Allow for special representation of smoothing parameter near 1
if j==1 && get(hand.method,'Value')==2
    newValue = shortstr( newValue , '', 1 );
end
set(hand.params(2,j), 'String', newValue );

% ... and invoke its callback
iDoCallback( hand.params(2,j) );
end  % iDoPlusMinus

function iDoPrintGraph(hand)
% iDoPrintGraph   Preserve current graphs as separate figure

figpos = get(hand.figure,'Position');
listpos = get(hand.listframe,'Position');
bottpos = get(hand.bottomlinetext,'Position');
shiftx = sum(listpos([1,3]))*figpos(3);
shifty = sum(bottpos([2,4]))*figpos(4);
pfigpos = figpos + [shiftx,shifty,-shiftx,-shifty];
xyscale = figpos(3:4)./pfigpos(3:4);

printfig = figure(...
    'ToolBar','figure',...
    'WindowStyle', 'normal', ...
    'Units','normalized', ...
    'Position',pfigpos, ...
    'NumberTitle','off',  ...
    'HandleVisibility','on', ...
    'Name', getString(message('SPLINES:resources:PrintToFigureTitle', showtime )) );
curcontext = get(hand.Axes(1),'UIContextMenu');
set(get(hand.Axes(1),'Children'),'UIContextMenu',[])
copyobj(hand.Axes(1), printfig);
set(get(hand.Axes(1),'Children'),'UIContextMenu',curcontext)
axepos = get(hand.Axes(1),'Position');
axepos(1:2) = axepos(1:2).*xyscale-[shiftx, shifty]./pfigpos(3:4);
axepos(3:4) = axepos(3:4).*xyscale;
set(findobj(printfig,'Tag','Axes1'), ...
    'ButtonDownFcn','', ...
    'Position', axepos, ...
    'UIContextMenu',[])
if any(get(hand.viewmenu,'UserData'))
    copyobj(hand.Axes(2),printfig);
    axepos = get(hand.Axes(2),'Position');
    axepos(1:2) = axepos(1:2).*xyscale-[shiftx, shifty]./pfigpos(3:4);
    axepos(3:4) = axepos(3:4).*xyscale;
    set(findobj(printfig,'Tag','Axes2'), ...
        'ButtonDownFcn','', ...
        'Position', axepos, ...
        'UIContextMenu',[])
end

if isequal(get(hand.tool(2),'Checked'),'on')
    % in order to ensure that the legend has the same relative position
    % in the print_axis as in Axes1, we need to make the following
    % calculations:
    oldpos = get(hand.Axes(1),'Position');
    newpos = get(findobj(printfig,'Tag','Axes1'),'Position');
    legpos = get(get(hand.Axes(1),'Legend'),'Position');
    scales = newpos(3:4)./oldpos(3:4);
    set_legend(hand,findobj(printfig,'Tag','Axes1'), ...
        [newpos(1:2)+scales.*(legpos(1:2)-oldpos(1:2)), ...
        scales.*legpos(3:4)], false );
end
end  % iDoPrintGraph

function iDoDuplicateSpline(hand,hc)
% iDoDuplicateSpline   Start a new spline as a replica of the current spline

% set up a new line as current line, updating the list
oldnameline = hand.nameline;
[currentname, hand.nameline] = add_to_list(hand);
dboldname = hand.dbname;
hand.name = currentname;
hand.dbname = deblank(currentname);
set(gcbf,'UserData',hand)

% copy the stuff from the old current line to the new line
lineud = get(oldnameline,'UserData');
if lineud.method==3|| ...
        (lineud.method==4&&isfield(lineud,'kc'))
    % put latest fit into knot calculations, just in case
    lineud = update(hand,'fit',lineud);
    lineud.kc(end+1) = addchange(hc, ...
        [hand.dbname,' = ',dboldname,'; ', ...
        '%% replicate the current approximation']);
end
% change the bottom line to the new name (looks strange if most recent
%    fit used newknt )
lineud.bottom = [' ', hand.dbname, ...
    lineud.bottom(strfind(lineud.bottom(1:14), ' ='):end)];
set(hand.bottomlinetext, 'String',lineud.bottom)
set(hand.nameline, ...
    'XData',get(oldnameline,'XData'),...
    'YData',get(oldnameline,'YData'),...
    'UserData',lineud);

% no need to update endconds, model, rest of display, except for
set_view_label(currentname,hand)
set_legend(hand,hand.Axes(1))

end  % iDoDuplicateSpline

function iDoDuplicateKnot(hand,hc)
% iDoDuplicateSpline   Replicate the marked knot

switch get(hand.method,'Value')
    case 3
        V = get(hand.params(1,4),'Value');
        lineud = get(hand.nameline,'UserData');
        index = find(lineud.knots==lineud.knots(V));
        if length(index)>=lineud.k
            warndlg(getString(message('SPLINES:resources:dlg_KnotsGreaterThanOrder')));
            return
        end
        lineud.knots = lineud.knots([1:V,V:end]);
        lineud = update(hand,'knots',lineud);
        sV = num2str(V);
        lineud.kc(end+1) = iAddCommentedChange( hc, ...
            sprintf( 'knots = knots([1:%s,%s:end]);', sV, sV ), ...
            message( 'SPLINES:resources:comment_ReplicateKnot' ) );
        set(hand.nameline,'UserData',lineud)
        set(hand.params(1,4),'String',lineud.knots(:), 'Value', V+1 )
        set(hand.params(4,4),'String',(lineud.knots(end)-lineud.knots(1))/(10*length(lineud.knots)))
        % update knots display
        iMarkBreak(hand),
        set_bdisplay(lineud.knots,hand)
        
        get_approx(hand)
        
end % switch get(hand.method,'Value')
end  % iDoDuplicateKnot

function iDoRestart()
switch get(gcbo,'Tag')
    case 'restart'
        answer = questdlg(sprintf('%s\n%s',getString(message('SPLINES:resources:dlg_Restart')), ...
            getString(message('SPLINES:resources:dlg_LoseUnsavedData'))), ...
            getString(message('SPLINES:resources:dlgTitle_RestartTool')),...
            getString(message('SPLINES:resources:uicontrol_OK')),...
            getString(message('SPLINES:resources:uicontrol_Cancel')),...
            getString(message('SPLINES:resources:uicontrol_OK')));
    case 'import_data'
        answer = questdlg(sprintf('%s\n%s',getString(message('SPLINES:resources:dlg_RestartToImport')),...
            getString(message('SPLINES:resources:dlg_LoseUnsavedData'))), ...
            getString(message('SPLINES:resources:dlgTitle_ImportData')),...
            getString(message('SPLINES:resources:uicontrol_OK')),...
            getString(message('SPLINES:resources:uicontrol_Cancel')),...
            getString(message('SPLINES:resources:uicontrol_OK')));
end
if isempty(answer) || strcmp(answer,getString(message('SPLINES:resources:uicontrol_Cancel')))
    return
end
splinetool 'closefile'
splinetool

end  % iDoRestart

function iDoWriteMatlabFile(hand,hc)
% check whether any of the visible fits involves edited data or user-
% supplied knots or weights

[filePath,fullfilename,functionName] = iGetFilenameToWriteMatlabCode();
if isempty( fullfilename )
    return
end

% start the file
[mfid,mess] = fopen(fullfilename,'w+');
if mfid==-1
    errordlg(getString(message('SPLINES:resources:dlg_BadFile',fullfilename,mess)),...
        getString(message('SPLINES:resources:dlgTitile_BadFilename')),'modal')
    return
end

iGenerateCode(hand,hc,mfid,functionName);

% finish the file and close it.
fclose(mfid);
fprintf( '%s\n',getString(message('SPLINES:resources:codegen_FileLocation', functionName, filePath(1:end-1))) );
end  % iDoWriteMatlabFile


function hMenu = iDoCreateSubmenu(hParent, type)
% iDoCreateSubMenu Create submenus for context menus and the edit menu 
switch type
  case 'add_item'
    hMenu = uimenu(hParent,'Label',getString(message('SPLINES:resources:menu_Add')), ...
                   'Callback', 'splinetool ''add_item''', ...
                   'Tag','add_item');
  case 'rep_knot'
    hMenu = uimenu(hParent,'Label',getString(message('SPLINES:resources:menu_ReplicateKnot')), ...
                   'Callback','splinetool ''rep_knot''','Tag','rep_knot');
  case 'del_item'
    hMenu = uimenu(hParent,'Label',getString(message('SPLINES:resources:menu_Delete')), ...
                   'Callback','splinetool ''del_item''',...
                   'Tag','del_item');    
end
end %iDoCreateSubmenu

function hLine = iDoCreateBreaksLine(hparent, breakcolor)
    
    hLine = line(...
        'Parent', hparent, ...
        'XData',NaN, 'YData',NaN,...
        'LineWidth',1.5, ...
        'Color',breakcolor, ...
        'Visible','off', ...
        'UserData','off', ...
        'ButtonDownFcn', 'splinetool ''axesclick''', ...
        'Tag','breaks');
    
end %iDoCreateBreaksLine

function iDoFinalize(y)
% iDoFinalize   Finish the rest of the gui figure:

hand = y;
[x,xname,y,yname,isf,startmethod] = deal(hand.xynames{:});
hand = rmfield(hand,'xynames');

backgrey = repmat(0.752941176470588,1,3);
breakcolor =  backgrey*.8; % would have liked just backgrey
currentcolor = [0 0 1];
highcolor =  [1 1 1];
framecolor = get(hand.figure,'Color');
units = 'normalized';

%  make up your own menubar items:
h1 = uimenu(hand.figure,'Label',getString(message('SPLINES:resources:menu_File')),'Tag','file');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Restart')), ...
    'Callback','splinetool ''restart''', ...
    'Tag','restart');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ImportData')), ...
    'Callback','splinetool ''restart''', ...
    'Separator','on',...
    'Tag','import_data');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ExportData')), ...
    'Callback','splinetool ''export_data''', ...
    'Separator','on',...
    'Tag','export_data');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ExportSpline')), ...
    'Callback','splinetool ''export_spline''', ...
    'Tag','export_spline');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_GenerateCode')), ...
    'Callback','splinetool ''save2mfile''', ...
    'Tag','save2mfile');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_PrintToFigure')), ...
    'Callback','splinetool ''print_graph''', ...
    'Separator','on',...
    'Tag','print_graph');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Close')), 'Callback', 'splinetool ''finish''', ...
    'Separator','on',...
    'Tag','exit');
h1 = uimenu(hand.figure,'Label',getString(message('SPLINES:resources:menu_Edit')),...
    'Tag','editmenu');
hand.undo = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Undo')),'UserData',[], 'Enable','off' ,...
    'Callback','splinetool ''undo''','Tag','undo');
hand.add_item = iDoCreateSubmenu(h1,'add_item');
hand.rep_knot = iDoCreateSubmenu(h1,'rep_knot');
hand.del_item = iDoCreateSubmenu(h1,'del_item');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Labels')), 'Callback', ...
    'splinetool ''labels''', 'Tag','labels');
hand.editmenu = h1;
viewud = [0 0 0];
h1 = uimenu(hand.figure,'Label',getString(message('SPLINES:resources:menu_View')),'UserData',viewud, ...
    'Tag','viewmenu');
hand.view(1) = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Show1stDerivative')), ...
    'Callback','splinetool ''view''', ...
    'Tag','ViewFirstDerivative');
hand.view(2) = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Show2ndDerivative')), ...
    'Callback','splinetool ''view''', ...
    'Tag','ViewSecondDerivative');
hand.view(3) = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ShowError')), ...
    'Callback','splinetool ''view''', ...
    'Tag','ViewErrorCurve');
hand.viewmenu = h1;
h1 = uimenu(hand.figure,'Label',getString(message('SPLINES:resources:menu_Tools')), 'Tag','toolmenu');
hand.tool(1) = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ShowGrid')), ...
    'Callback','splinetool ''tool''', ...
    'Tag','showgridmenu');
hand.tool(2) = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ShowLegend')), ...
    'Callback','splinetool ''tool''', ...
    'Checked','on', 'Tag','showlegendmenu');
hand.toolmenu = h1;

% Create help menu
h1 = uimenu(hand.figure,'Label',getString(message('SPLINES:resources:menu_Help')));
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_SplinetoolHelp')), ...
    'Tag', 'Splinetool-Help', ...
    'Callback','doc splinetool');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_QuickOverview')),...
    'Tag', 'Splinetool-Quick-Overview', ...
    'Callback','splinetool(''help'',''about the GUI'')');

h2 = uimenu(h1,'Label',getString(message('SPLINES:resources:menu_ExplanationOfTerms')),'Tag','help');
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Bspline')),...
    'Callback','splinetool(''help'',''B-spline'')');
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_BasicInterval')),...
    'Callback','splinetool(''help'',''basic interval'')');
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Breaks')),'Callback','splinetool(''help'',''breaks'')');
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Error')), 'Callback', ...
    'splinetool(''help'',''error'')');
h3 =  uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Forms')));
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_Bform')), ...
    'Callback','splinetool(''help'',''B-form'')');
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_ppform')), ...
    'Callback','splinetool(''help'',''ppform'')');
h3 =  uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Interpolation')));
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_CubicSplineInterpolation')), ...
    'Callback','splinetool(''help'',''cubic spline interpolation'')');
h4 = uimenu(h3,'Label',getString(message('SPLINES:resources:menu_EndConditions')));
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_Remark')), ...
    'Callback','splinetool(''help'',''endconditions'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_NotAKnot')), ...
    'Callback','splinetool(''help'',''not-a-knot'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_ClampedOrComplete')), ...
    'Callback','splinetool(''help'',''clamped'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_Second')), ...
    'Callback','splinetool(''help'',''second'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_Periodic')), ...
    'Callback','splinetool(''help'',''periodic'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_VariationalOrnatural')), ...
    'Callback','splinetool(''help'',''variational'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_Lagrange')), ...
    'Callback','splinetool(''help'',''Lagrange'')')
uimenu(h4,'Label',getString(message('SPLINES:resources:menu_Customized')), ...
    'Callback','splinetool(''help'',''Customized'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_SplineInterpolation')), ...
    'Callback','splinetool(''help'',''spline interpolation'')');

h3 = uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Knots')));
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_EndKnots')), ...
    'Callback','splinetool(''help'',''end knots'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_InteriorKnots')),...
    'Callback','splinetool(''help'',''interior knots'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_Knots')),'Callback','splinetool(''help'',''knots'')');
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_LeastSquares')), ...
    'Callback','splinetool(''help'',''least squares'')');

uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Order')), 'Callback','splinetool(''help'',''order'')')
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_SchoenbergWhitneyConditions')), ...
    'Callback','splinetool(''help'',''Schoenberg-Whitney conditions'')');

uimenu(h2,'Label',getString(message('SPLINES:resources:menu_SitesAndValues')), ....
    'Callback','splinetool(''help'',''sites_etc'')');
h3 =  uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Smoothing')));
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_CubicSmoothingSpline')), 'Callback', ...
    'splinetool(''help'',''cubic smoothing spline'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_QuinticSmoothingSpline')), 'Callback', ...
    'splinetool(''help'',''quintic smoothing spline'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_ErrorMeasure')), 'Callback', ...
    'splinetool(''help'',''error'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_RoughnessMeasure')), 'Callback', ...
    'splinetool(''help'',''roughness measure'')')
uimenu(h3,'Label',getString(message('SPLINES:resources:menu_WeightInRoughnessMeasure')), 'Callback', ...
    'splinetool(''help'',''weight in roughness measure'')')
uimenu(h2,'Label',getString(message('SPLINES:resources:menu_Spline')),'Callback','splinetool(''help'',''spline'')');

uimenu(h1,'Label',getString(message('SPLINES:resources:menu_CurveFittingToolboxHelp')), ...
    'Tag', 'Splinetool-Curvefit-Help', ...
    'Separator','on', ...
    'Callback', @helpOnCurvefitToolbox );
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_Demos')), ...
    'Tag', 'Splinetool-Demos', ...
    'Callback','demo toolbox curve');
uimenu(h1,'Label',getString(message('SPLINES:resources:menu_About')),...
    'Tag', 'Splinetool-About', ...
    'Separator','on', ...
    'Callback','splinetool(''help'',''about'')');

% also provide a context menu, to be active in data mode, and to provide
% the same capability as the edit commands
hand.context = uicontextmenu('Parent',hand.figure, ...
    'Position',[.35 .46], ...
    'Tag','context');

hand.add_item(2) = iDoCreateSubmenu(hand.context,'add_item');
hand.rep_knot(2) = iDoCreateSubmenu(hand.context,'rep_knot');
hand.del_item(2) = iDoCreateSubmenu(hand.context,'del_item');

mat2 = [
    0         0    1.0000
    0    0.5000         0
    1.0000         0         0
    0    0.7500    0.7500
    0.7500         0    0.7500
    0.7500    0.7500         0
    0.2500    0.2500    0.2500
    ];
xaxes = .35;
dxaxes = .63;

% the axes on which to draw derivatives and such
% lower plot
hand.Axes(2) = axes('Parent',hand.figure, ...
    'CameraUpVector',[0 1 0], ...
    'CameraUpVectorMode','manual', ...
    'Color',highcolor, ...
    'ColorOrder', mat2, ...
    'Position',[xaxes .11 dxaxes .316], ...
    'Visible','off', ...
    'Tag','Axes2', ...
    'Box','on', ...
    'ButtonDownFcn','splinetool ''axesclick''', ...
    'XColor',[0 0 0], ...
    'YColor',[0 0 0], ...
    'ZColor',[0 0 0]);
xlabel( hand.Axes(2), xname );
ylabel( hand.Axes(2), '' );

hand.zeroline = line(...
    'Parent', hand.Axes(2), ...
    'XData',[NaN NaN],'YData',[0 0], ...
    'LineWidth',1.5, ...
    'Color',breakcolor, ...
    'Visible','off', ...
    'Tag','zeroline');
hand.viewline = line(...
    'Parent', hand.Axes(2), ...
    'XData',NaN,'YData',NaN, ...
    'Color',currentcolor, ...
    'LineWidth',2, ...
    'Tag','viewline');
% put break/knot lines (also) on second graphic
hand.breaks(2) = iDoCreateBreaksLine(hand.Axes(2), breakcolor);

% axes on which to draw data and approximations
% upper plot
hand.Axes(1) = axes('Parent',hand.figure, ...
    'CameraUpVector',[0 1 0], ...
    'CameraUpVectorMode','manual', ...
    'Color',highcolor, ...
    'ColorOrder', mat2, ...
    'Units', units, ...
    'Position',[xaxes 0.47 dxaxes 0.497], ...
    'Tag','Axes1', ...
    'Box','on', ...
    'ButtonDownFcn','splinetool ''axesclick''', ...
    'UIContextMenu',hand.context, ...
    'XColor',[0 0 0], ...
    'YColor',[0 0 0], ...
    'ZColor',[0 0 0]);
xlabel( hand.Axes(1), xname );
ylabel( hand.Axes(1), yname );

% make sure the x limits are the same for the upper and lower plots
hand = iLinkXLims(hand);

%  set up bottom line for showing toolbox commands used:
hand.bottomlinetext = uicontrol('Parent',hand.figure, ...
    'BackgroundColor',highcolor, ...
    'ListboxTop',0, ...
    'Units',units, ...
    'Position',[.124 .003 .876 .046], ...
    'Style','text', ...
    'HorizontalAlignment','left', ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_CommandUsed')), ...
    'Tag','bottomlinetext');

uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'ListboxTop',0, ...
    'Units',units, ...
    'Position',[.014 .023 .10 .026], ...
    'String',getString(message('SPLINES:resources:label_Bottomline')), ...
    'Style','text')

%  %  the spline/name manager
mmpos = [.015 .77-.007, .101, .18];
marg = .008;
hand.listframe = uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'Units',units, ...
    'Position',[mmpos(1:2)-marg,.25+2*marg,mmpos(4)+3.5*marg], ...
    'Style','frame', ...
    'Tag','nameframe');
uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'Units',units, ...
    'Position',[mmpos(1)+.005, mmpos(2)+mmpos(4),.19, 4*marg], ...
    'HorizontalAlignment','left', ...
    'String',getString(message('SPLINES:resources:label_ListOfApproximations')), ...
    'Style','text')

sl = .032;
rw = .15;
lnpx = rw-sl;
lnpy = mmpos(2);
ww = lnpx-mmpos(1);
wh = .045;
ph = 3*wh;
hand.ask_show = uicontrol('Parent',hand.figure, ...
    'ListboxTop',0, ...
    'Units',units, ...
    'Position',[lnpx+.002 lnpy rw wh], ...
    'Style','checkbox', ...
    'String',getString(message('SPLINES:resources:uicontrol_ShownInGraph')), ...
    'Callback', 'splinetool ''toggle_show''', ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_ShowHidePlot')), ...
    'Tag','ask_show');

% list of names
listud.handles = [];
listud.length=0;
listud.untitleds=0;
hand.list_names = uicontrol('Parent',hand.figure, ...
    'BackgroundColor',highcolor, ...
    'Units',units, ...
    'Position',[lnpx lnpy+wh rw ph], ...
    'String',{''}, ...
    'Style','listbox', ...
    'Tag','list_names', ...
    'Callback','splinetool ''make_current''', ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_Current')), ...
    'UserData',listud, ...
    'Value',1);

%  Pushbutton NEW : start another curve with the default fit
uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'ListboxTop',0, ...
    'Position',[mmpos(1),mmpos(2)+3*wh,ww wh], ...
    'String',getString(message('SPLINES:resources:uicontrol_New')), ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_New')), ...
    'Callback','splinetool ''new''', ...
    'Tag','Pushnew');
%  Pushbutton REP : start another curve, a copy of current one
uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'ListboxTop',0, ...
    'Position',[mmpos(1),mmpos(2)+2*wh,ww wh], ...
    'String',getString(message('SPLINES:resources:uicontrol_Replicate')), ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_Replicate')), ...
    'Callback','splinetool ''rep''', ...
    'Tag','Pushrep');
%  Pushbutton DEL : delete the current curve
uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'ListboxTop',0, ...
    'Position',[mmpos(1),mmpos(2)+wh,ww wh], ...
    'String',getString(message('SPLINES:resources:uicontrol_Delete')), ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_Delete')), ...
    'Callback','splinetool ''del''', ...
    'Tag','Pushdel');
%  Pushbutton RENAME : rename current spline
hand.ask_name = uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'Position',[mmpos(1),mmpos(2),ww wh], ...
    'String',getString(message('SPLINES:resources:uicontrol_Rename')), ...
    'Callback', 'splinetool ''change_name''', ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_Rename')), ...
    'Tag','ask_name');

%  the method manager
topy = mmpos(2)-.07;
edy = .0013;
wh = .036;
mpx = mmpos(1);
mpy = topy-wh;
mw=.25;
bottomy = mpy-4*(wh+edy)-.03;
uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'Units',units, ...
    'Position',[[mpx,bottomy]-marg,mw+2*marg,topy-bottomy+3.5*marg], ...
    'Style','frame', ...
    'Tag','nameframe')
uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'Units',units, ...
    'Position',[mmpos(1)+.005, topy,.19, 4*marg], ...
    'HorizontalAlignment','left', ...
    'String',getString(message('SPLINES:resources:label_ApproximationMethod')), ...
    'Style','text')
hand.method = uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'BackgroundColor',highcolor, ...
    'ListboxTop',0, ...
    'Position',[mpx mpy mw wh], ...
    'HorizontalAlignment','center', ...
    'Style','popupmenu', ...
    'String',{getString(message('SPLINES:resources:CubicSplineInterpolation'));
    getString(message('SPLINES:resources:SmoothingSpline'));
    getString(message('SPLINES:resources:LeastSquaresApproximation'));
    getString(message('SPLINES:resources:SplineInterpolation'))}, ...
    'Callback','splinetool ''method''', ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_Method')), ...
    'Tag','method', ...
    'Interruptible','off', ...
    'Enable', 'on', ...
    'Value',1);

%  additional parameters
ew = .12;
hand.endtext = uicontrol('Parent',hand.figure, ...
    'Style','text', ...
    'Units',units, ...
    'Position',[mpx mpy-wh-4*edy-.007 ew wh], ...
    'BackgroundColor',framecolor, ...
    'String',getString(message('SPLINES:resources:label_EndConditions')), ...
    'Tag','endtext')   ;

%  ... for cubic spline interpolation
hand.endconds = uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'BackgroundColor',highcolor, ...
    'ListboxTop',0, ...
    'Position',[mpx+(mw-ew) mpy-wh-4*edy ew wh], ...
    'String',{'not-a-knot';'clamped';'complete';'second';'periodic'; ...
    'variational';'natural';'Lagrange';'Custom'}, ...
    'Style','popupmenu', ...
    'Callback','splinetool ''parameters''', ...
    'TooltipString', getString(message('SPLINES:resources:tooltip_EndConditions')), ...
    'Visible','off', ...
    'Tag','endconds', ...
    'Value',1);

%  ... for everything else, we have order
currlist = {'1';'2';'3';'4';'5';'6';'7';'8';'9';'10';'11';'12';'13';'14'};
hand.order = uicontrol('Parent',hand.figure, ...
    'BackgroundColor',highcolor, ...
    'Units',units, ...
    'Position',get(hand.endconds,'Position'), ...
    'HorizontalAlignment','center',...
    'Style','popupmenu',...
    'String',currlist, ...
    'Callback','splinetool ''change_order''', ...
    'UserData',currlist, ...
    'Value',4, ...
    'TooltipString',getString(message('SPLINES:resources:tooltip_Order')), ...
    'Visible','off','Tag','order');

%  set up the remaining parameter display
centerx = mpx+mw/2;
wid = mw/2;

%  left end toggle
hand.partext(1,1) = uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'BackgroundColor',framecolor, ...
    'Position',[centerx-wid bottomy+3*(wh+edy)-.015 wid-.001 wh], ...
    'Style','text', ...
    'Visible','on', ...
    'String',getString(message('SPLINES:resources:label_LeftEnd')));
hand.partext(2,1) = copyobj(hand.partext(1,1),hand.figure);
set(hand.partext(2,1), ...
    'Position',[centerx-wid bottomy+2*(wh+edy) wid-.001 wh], ...
    'Visible','off', ...
    'String',getString(message('SPLINES:resources:label_Parameter')))
hand.params(1,1) = uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'ListboxTop',0, ...
    'Position',get(hand.partext(2,1),'Position'), ...
    'UserData','pushend', ...
    'Tag','pushbuttonleft', ...
    'String',getString(message('SPLINES:resources:uicontrol_x1stDeriv')), ...
    'Callback', 'splinetool(''toggle_ends'',''left'')', ...
    'Value',1);
hand.params(2:5,1) = clickable(hand.figure,...
    [centerx-wid,bottomy], wid, 'left','parameters','endconds');

%  rite end toggle
hand.partext(1,2) = copyobj(hand.partext(1,1),hand.figure);
set(hand.partext(1,2), ...
    'Position',[centerx+.001 bottomy+3*(wh+edy)-.015 wid-.001 wh], ...
    'String',getString(message('SPLINES:resources:label_RightEnd')))
hand.partext(2,2) = copyobj(hand.partext(1,2),hand.figure);
set(hand.partext(2,2), ...
    'Position',[centerx+.001 bottomy+2*(wh+edy) wid-.001 wh], ...
    'String',getString(message('SPLINES:resources:label_Tolerance')))
hand.params(1,2) = copyobj(hand.params(1,1),hand.figure);
set(hand.params(1,2), ...
    'Position',get(hand.partext(2,2),'Position'), ...
    'String',getString(message('SPLINES:resources:uicontrol_x1stDeriv')), ...
    'Callback', 'splinetool(''toggle_ends'',''rite'')', ...
    'Tag','pushbuttonrite')
hand.params(2:5,2) = clickable(hand.figure,...
    [centerx,bottomy], wid, 'rite','parameters','endconds');
set(hand.params(2:5,1:2),'Enable','off')
%   popup re lists
dkpx = mmpos(1);
dkpy = .111;
dkw=.125;
dkh = .265;
datatop = dkpy+dkh+.01+wh;
databottom = dkpy+wh-(2*wh+.002);
uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'Units',units,'Position', ...
    [[dkpx,databottom]-marg,2*(dkw+marg),(datatop-databottom)+3.5*marg], ...
    'Style','frame', ...
    'Tag','nameframe')
uicontrol('Parent',hand.figure, ...
    'BackgroundColor',framecolor, ...
    'Units',units, ...
    'Position',[dkpx+.005, datatop,.25, 4*marg], ...
    'String',getString(message('SPLINES:resources:label_DataBreaksknotsWeights')), ...
    'HorizontalAlignment','left', ...
    'Style','text')


hand.data_etc = uicontrol('Parent',hand.figure, ...
    'Units',units, ...
    'Position',[dkpx dkpy+dkh+.01 2*dkw wh], ...
    'BackgroundColor',highcolor, ...
    'ListboxTop',0, ...
    'HorizontalAlignment','left', ...
    'Style','popupmenu', ...
    'Callback','splinetool ''data_etc''', ...
    'Tag','data_etc', ...
    'Interruptible','off', ...
    'Enable', 'on', ...
    'Value',1);

% also make the three lists and their clickable and edit field, but keep them all
% invisible, to be turned on as needed.

poss = 'lmr';
shift = [0 0 1]*dkw;

for j=3:5
    hand.params(1,j) = uicontrol('Parent',hand.figure, ...
        'Units',units, ...
        'BackgroundColor','w', ...
        'Position',[dkpx+shift(j-2),dkpy+wh, dkw, dkh-wh], ...
        'String',[], ...
        'Style','listbox', ...
        'Tag',['list',poss(j-2)], ...
        'Enable','on', ...
        'Visible','off', ...
        'Value',1);
    %  'CallBack','splinetool ''align''', ...
    
    % put a clickable underneath:
    hand.params(2:5,j) = clickable(hand.figure,...
        [dkpx+shift(j-2),databottom],dkw,...
        ['clk',poss(j-2)],'move_item','listlmr');
    
    if j==4  % also provide a button to the right of the top:
        hand.buttonm = uicontrol('Parent',hand.figure, ...
            'Units',units, 'Position', ...
            [dkpx+shift(j-2)+dkw+.02,dkpy+dkh-wh-.001, .083, wh], ...
            'String',getString(message('SPLINES:resources:label_Adjust')), ...
            'Callback','splinetool ''newknt''', ...
            'TooltipString',...
            getString(message('SPLINES:resources:tooltip_Adjust')),...
            'Tag','buttonm', ...
            'Visible','off');
        % ... and show the number of pieces in an edit box:
        hand.piecem = uicontrol('Parent',hand.figure, ...
            'BackgroundColor',highcolor, ...
            'Units',units, 'Position', ...
            [dkpx+shift(j-2)+dkw+.028,databottom, .075, wh], ...
            'Style','edit', ...
            'String',' ', ...
            'Callback','splinetool ''pieces''', ...
            'TooltipString',getString(message('SPLINES:resources:tooltip_Pieces')),...
            'Tag','piecem', ...
            'Visible','off');
        % ... and label that edit box:
        hand.piecetext = uicontrol('Parent',hand.figure, ...
            'BackgroundColor',framecolor, ...
            'Units',units, 'Position', ...
            get(hand.piecem,'Position')+[0,wh,0,0], ...
            'Style','text', ...
            'String',getString(message('SPLINES:resources:label_Pieces')), ...
            'Tag','piecetext', ...
            'Visible','off');
        % also remove the callback
        % set(hand.params(1,4),'CallBack',[])
    end
    
end %for j=3:5

hand.highlightxy = line(...
    'Parent', hand.Axes(1), ...
    'XData',NaN, 'YData',NaN,...
    'Marker','o','LineStyle','none',...
    'LineWidth',3, ...
    'Color','r', ...
    'Visible','off', ...
    'Tag','highlightxy');

hand.breaks(1) = iDoCreateBreaksLine(hand.Axes(1), breakcolor);
hand.highlightb = line(...
    'Parent', hand.Axes(1), ...
    'XData',NaN, 'YData',NaN,...
    'LineWidth',2, ...
    'Color','r', ...
    'Visible','off', ...
    'Tag','highlightb');

% set up the dataline and data display
hand.dataline = line(...
    'Parent', hand.Axes(1), ...
    'XData',NaN,'YData',NaN,...
    'Marker','o','LineStyle','none',...
    'ButtonDownFcn', 'splinetool ''axesclick''', ...
    'UserData',isf, ...
    'Tag','1');
set(hand.highlightxy,'UserData',[x(:).'; y(:).'])

hand.currentline = line(...
    'Parent', hand.Axes(1), ...
    'XData',NaN,'YData',NaN, ...
    'LineWidth',2, ...
    'Color',currentcolor, ...
    'ButtonDownFcn', 'splinetool ''axesclick''', ...
    'Tag','currentline');

hand = iNewSpline(hand,startmethod);
iViewLowerPlot(hand.view(3),3,hand)
set(hand.currentline,'UserData',{}); % initialize changes array

set( hand.figure, ...
    'UserData', hand, ...
    'Pointer', 'arrow',  ...
    'Visible', 'on', ...
    'CloseRequestFcn', 'splinetool ''finish''' );

% if any data provided a special message, show it now:
if isfield(hand,'messh')
    temp = msgbox(hand.messh{1},hand.messh{2},hand.messh{3});
    set(temp,'Tag','Spline Tool Example Message Box')
end
end  % iDoFinalize

function iDoToggleEnds(hand, whichEnd)
% iDoToggleEnds   Toggle the left/rite endcondition button
%
%  whichEnd should be 'left' or 'rite'.
if strcmp(whichEnd,'left')
    j=1;
else
    j=2;
end
toggle_ends(j,hand);
end  % iDoToggleEnds

function iDoToggleShowSpline(hand)
% iDoToggleShowSpline   Toggle whether the current spline is plotted

C = get(hand.list_names,'Value');
names = get_names(get(hand.list_names,'String'));
if get(hand.ask_show,'Value')==0  % need to turn off the plotting
    set([hand.currentline,hand.nameline],'Visible','off')
    names(C,1) = ' ';
else     % need to turn on the plotting
    set([hand.currentline,hand.nameline],'Visible','on')
    names(C,1) = 'v';
end

set(hand.list_names,'String',{names})
set_legend(hand,hand.Axes(1),get(get(hand.Axes(1),'Legend'),'Position'))

end  % iDoToggleShowSpline

function iDoToggleTool(hand)
clicked = gcbo;
tag = get(clicked,'Tag');
[~, ip] = ismember( tag, {'showgridmenu', 'showlegendmenu'} );

if isequal(get(hand.tool(ip),'Checked'),'on')
    set_tools(hand,ip,'off')
else
    set_tools(hand,ip,'on')
end
end  % iDoToggleTool

function iDoUndo(hand)
% iDoUndo   Undo the most recent change, so far only in data

set(hand.undo,'Enable','off')
undoud = get(hand.undo,'UserData');
if isfield(undoud,'lineud')
    set(hand.nameline,'UserData',undoud.lineud)
end
set_data(hand,undoud.xy(1,:),undoud.xy(2,:))
get_approx(hand)

end  % iDoUndo

function iDoViewLowerPlot(hand)
clicked = gcbo;
tag = get(clicked,'Tag');
[~, ip] = ismember( tag, {'ViewFirstDerivative', 'ViewSecondDerivative', 'ViewErrorCurve'} );
iViewLowerPlot(clicked,ip,hand)

end  % iDoViewLowerPlot

function iDoBadInputErrorDialog()
errordlg( ...
    getString(message('SPLINES:resources:dlg_StringOneInput')), ...
    getString(message('SPLINES:resources:dlgTitle_BadInput')),'modal')

end  % iDoBadInputErrorDialog

function iStartSplineTool( x, y )

if nargin
    % check and sort the given data
    [x, y] = chckxy( x, y );
    xname = 'x';
    yname = 'y';
    isf = 0;
end


running = findobj(allchild(0),'Name',getString(message('SPLINES:resources:SplineTool')));
if ~isempty(running)
    ignore = 1;
    if nargin
        answer = questdlg(sprintf('%s\n%s',getString(message('SPLINES:resources:dlg_RestartWithNewData')), ...
            getString(message('SPLINES:resources:dlg_LoseUnsavedData'))), ...
            getString(message('SPLINES:resources:dlgTitle_RestartTool')),...
            getString(message('SPLINES:resources:uicontrol_OK')),...
            getString(message('SPLINES:resources:uicontrol_Cancel')),...
            getString(message('SPLINES:resources:uicontrol_OK')));
        if isequal(answer,getString(message('SPLINES:resources:uicontrol_OK')))
            splinetool 'closefile'
            ignore = 0;
        end
    end
    if ignore,
        figure(running);
        return
    end
end

mat0 = load( 'splinetool' );

% the basic figure
hand.figure = figure(...
    'Colormap',mat0.mat0, ...
    'WindowStyle','normal', ...
    'DockControls','off', ...
    'FileName','splinetool.m', ...
    'PaperUnits','normalized', ...
    'PaperPosition',[.25 .10 .65 .75], ...
    'Units','normalized', ...
    'Position',[.25 .10 .65 .75], ...
    'NumberTitle','off', ...
    'IntegerHandle','off',...
    'Name',getString(message('SPLINES:resources:SplineTool')), ...
    'Tag','splinetoolfig', ...
    'DeleteFcn','splinetool ''closefile''', ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'HandleVisibility', 'callback' );

% If there are no data yet, ask for some:
if nargin<1
    set_up_menu(hand.figure)
else
    set(hand.figure,'Visible','off')
    hand.xynames = {x,xname,y,yname,isf,1};
    splinetool('startfinish',hand)
end
end  % iStartSplineTool

function iContinueStartup( hand, buttonIndex )

cf = hand{1};
handles = hand{2};
hand = struct('figure',cf);
messtitle = sprintf('%s: ',getString(message('SPLINES:resources:dlgTitle_ExampleInfo')));
isf = 0;
errortit = getString(message('SPLINES:resources:dlgTitle_InvalidInput'));
startmethod = 1; % the default method to start is cubic spline interpolation
try
    % now call on my own version of the menu command
    % 'Specify a file that provides the data', ...
    % Note that any error now, in whatever function is being called,
    % such as ask_for_data with the possibility of incorrect function
    % or file names being supplied, will result in the immediate
    % termination, with the only comment the ones, if any, in the catch
    % phase.
    switch buttonIndex
        case 1 % user provides data
            [x,y,xname,yname,isf] = ask_for_data;
        case 3 % noisy values of a smooth function
            x = linspace(0,2*pi,101);
            y = sin(x)+(rand(size(x))-.5)*.2;
            hand.messh = ...
                {getString(message('SPLINES:resources:dlg_ExampleInfoSmoothFunction')), ...
                messtitle, 'non-modal'};
            xname = 'x= linspace(0,2*pi,101)';
            yname = 'sin';
            isf = 2;
        case 4 % sin(x) on [0 .. pi/2]
            x = linspace(0,pi/2,31);
            y = sin(x);
            xname = 'x = linspace(0,pi/2,31)';
            yname = 'sin';
            isf = 2;
            hand.messh = ...
                {getString(message('SPLINES:resources:dlg_ExampleInfoSin')), ...
                messtitle, 'non-modal'};
        case 5 % census data, taken from the matlab demo CENSUS
            censusData = load( 'census' );
            x = censusData.cdate;
            y = censusData.pop;
            xname = getString(message('SPLINES:resources:Year'));
            yname = getString(message('SPLINES:resources:Population'));
            hand.messh = ...
                {getString(message('SPLINES:resources:dlg_ExampleInfoCensus')), ...
                messtitle, 'non-modal'};
        case 6 % Richard Tapia's drag race data;
            % try to estimate the initial acceleration
            x = [ 0.000 0.857 2.142 3.074 3.862 4.4052 4.544];
            y = [ 0 60 330 660 1000 1254 1320];
            xname = getString(message('SPLINES:resources:TimeInSeconds'));
            yname = getString(message('SPLINES:resources:DistanceInFeet'));
            hand.messh = ...
                {getString(message('SPLINES:resources:dlg_ExampleInfoRaceData')), ...
                messtitle, 'non-modal'};
        case 7 % move knots to improve an interpolant
            [x,y] = titanium;
            pick =  [1 5 11 21 27 29 31 33 35 40 45 49];
            x = x(pick);
            y = y(pick);
            xname = getString(message('SPLINES:resources:Temperature'));
            yname = getString(message('SPLINES:resources:TitaniumProperty'));
            startmethod = 4; % start this one off with spline interpolation
            hand.messh = ...
                {getString(message('SPLINES:resources:dlg_ExampleInfoInterpolant')), ...
                messtitle, 'non-modal'};
            
        otherwise
            [x,y] = titanium;
            xname = getString(message('SPLINES:resources:Temperature'));
            yname = getString(message('SPLINES:resources:TitaniumProperty'));
            hand.messh = ...
                {getString(message('SPLINES:resources:dlg_ExampleInfoTitanium')), ...
                messtitle, 'non-modal'};
    end %switch menu getString(message('SPLINES:resources:dlg_ChooseData'));
catch laster
    cf = findobj(allchild(0),'Name',getString(message('SPLINES:resources:SplineTool')));
    if ~isempty(cf)
        errordlg({getString(message('SPLINES:resources:dlg_InvalidInput'));laster.message},errortit)
        splinetool 'closefile'
    end
    return
end %try

if ~exist('x','var')
    errordlg(getString(message('SPLINES:resources:dlg_UndefinedDataSites')),errortit)
    return
end
if ~exist('y','var')
    errordlg(getString(message('SPLINES:resources:dlg_UndefinedDataValues')),errortit)
    return
end
if length(x)~=length(y)
    errordlg(getString(message('SPLINES:resources:dlg_SameLengthSitesAndValues')),errortit)
    return
end

if isf<0 % the user hit Cancel (in case 1), so we try again
    set(cf,'UserData',{cf,handles},'Pointer','arrow')
else % if nothing went wrong, remove the menu and go to finish
    delete(handles),
    drawnow
    hand.xynames = {x,xname,y,yname,isf, startmethod};
    splinetool('startfinish',hand)
end
end  % iContinueStartup

function [setknots,setweights,settols,ic] = iPrepareOptionalArguments(lineud)
% iPrepareOptionalArguments   Prepare optional arguments, if any, for code
% generation.
setknots = 0;
setweights = 0;
settols = 0;
switch lineud.method
    case 1
    case 2
        if ~isempty(strfind( lineud.bottom(4:16), '= cs' ))||...
                (isfield(lineud,'wc')&&length(lineud.wc)>1)
            setweights = 1;
        end
        if isfield(lineud,'tc')&&length(lineud.tc)>1
            settols = 1;
        end
    case 3
        if isfield(lineud,'wc')&&length(lineud.wc)>1
            setweights = 1;
        end
        if isfield(lineud,'kc')&&~isempty(lineud.kc)
            setknots = 1;
        end
    case 4
        if isfield(lineud,'kc')&&~isempty(lineud.kc)
            setknots = 1;
        end
end
ic = [];
if isfield(lineud,'dc')
    ic = [ic,lineud.dc(2:end)];
end
if setknots
    ic = [ic,lineud.kc];
end
if setweights
    ic = [ic,lineud.wc];
end
if settols
    ic = [ic,lineud.tc];
end
end  % iPrepareOptionalArguments

function code = iCodeToDistributeJumpInRoughness( sV )
% iCodeToDistributeJumpInRoughness   Code to distribute jump in the roughness weight
%
% Inputs
%   sV   The index of the point as a string (char-array)

code = [
    'if dlam(',sV,')\n',...
    '    dlam(',sV,'-1) = dlam(',sV,'-1) + dlam(',sV,')/2;\n',...
    '    dlam(',sV,'+1) = dlam(',sV,'+1) + dlam(',sV,')/2;\n',...
    'end\n', ...
    'dlam(',sV,') = [];'
    ];
end  % iCodeToDistributeJumpInRoughness

function [filepath,fullfilename,filename] = iGetFilenameToWriteMatlabCode()

filepath = '';
fullfilename = '';
filename = '';

filenameChosen = false;

filterSpec = fullfile( pwd, '*.m' );
getfiletitle = getString(message('SPLINES:resources:dlgTitle_EnterAFilename'));

while ~filenameChosen
    [filename,filepath] = uiputfile( filterSpec, getfiletitle );
    if isequal(filename,0) || isequal(filepath,0)
        % the user hit Cancel, so give up on this
        filepath = '';
        fullfilename = '';
        filename = '';
        return
    else
        checked = 0;
        if length(filename)>2&&isequal(filename(end-1:end),'.m')
            % strip off terminal .m
            filename(end-1:end) = [];
            checked = 1;
        end
        if isvarname(filename) % if a valid name, check whether it is taken
            fullfilename = [filepath filename,'.m'];
            if ~exist(fullfilename, 'file')
                filenameChosen = true;
            else
                if checked
                    anss = getString(message('SPLINES:resources:uicontrol_Yes'));
                else
                    anss = questdlg( ...
                        getString(message('SPLINES:resources:dlg_FileExists', which( fullfilename )) ), ...
                        getString(message('SPLINES:resources:dlgTitle_FileExists')), ...
                        getString(message('SPLINES:resources:uicontrol_No')),...
                        getString(message('SPLINES:resources:uicontrol_Yes')),...
                        getString(message('SPLINES:resources:uicontrol_No')));
                end
                if isequal(anss,getString(message('SPLINES:resources:uicontrol_Yes')))
                    filenameChosen = true;
                end
            end
        else
            temp = errordlg( getString(message('SPLINES:resources:dlg_InvalidFilename', filename)) , ...
                getString(message('SPLINES:resources:dlgTitle_InvalidFilename')) );
            getfiletitle = getString(message('SPLINES:resources:dlgTitle_EnterAFilename'));
            waitfor(temp)
        end
    end
end
end  % iGetFilenameToWriteMatlabCode

function iGenerateCode(hand,hc,mfid,functionName)

names = get_names(get(hand.list_names,'String'));
listud = get(hand.list_names,'UserData');
datachanged = 0;
othermanual = 0;
vv = find(names(:,1)=='v').';
for v=vv
    lineud = get(listud.handles(v),'UserData');
    if lineud.dc(end)~=0
        datachanged = 1;
    end
    if (isfield(lineud,'kc')&&~isempty(lineud.kc))|| ...
            (isfield(lineud,'tc')&&length(lineud.tc)>1)|| ...
            (isfield(lineud,'wc')&&length(lineud.wc)>1)
        othermanual = 1;
    end
end

% depending on whether or not changed data are involved, ...
if datachanged
    z = '0';
    xArgument = 'x0';
    yArgument = 'y0';
else
    z = '';
    xArgument = 'x';
    yArgument = 'y';
end

fprintf(mfid, 'function %s(%s, %s)\n', functionName, xArgument, yArgument );
fprintf(mfid, '%% %s %s\n', upper(functionName), 'Reconstruct figure in SPLINETOOL.' );
fprintf(mfid, '%%\n' );
iWriteComment( mfid, message( 'SPLINES:resources:codegen_CreatePlotSimilarTo', sprintf( '%s(%s, %s)', upper(functionName), xArgument, yArgument ) ) );
iWriteComment( mfid, message( 'SPLINES:resources:codegen_YouCanApplyThisFunction' ) );

if datachanged || othermanual
    fprintf(mfid, '%%\n' );
    iWriteComment( mfid, message('SPLINES:resources:codegen_DataDependentChange') );
end
% append the help

if get(hand.dataline,'UserData')
    fprintf(mfid, '%%\n' );
    commandToGenerateDataValues = sprintf( '%s=feval(''%s'',%s)', yArgument, get(get(hand.Axes(1),'YLabel'),'String'), xArgument );
    iWriteComment( mfid, message('SPLINES:resources:codegen_DataValues', commandToGenerateDataValues, xArgument ) );
end

% now start by plotting the data.

V = get(hand.list_names,'Value');
fprintf(mfid, ['\n%%   ',getString(message('SPLINES:resources:codegen_DataInRows')),' ...\n', ...
    'x',z,' = x',z,'(:).''; y',z,' = y',z,'(:).'';\n', ...
    '%% ... ',getString(message('SPLINES:resources:codegen_PlotData')),...
    '\n\n']);
if datachanged % we need to generate them
    fprintf( mfid, 'x = %s;\n', xArgument );
    fprintf( mfid, 'y = %s;\n', yArgument );
    
    % get lineud.dc for current line
    lineud = get(listud.handles(V),'UserData');
    changes = get(hc,'UserData');
    for j=2:length(lineud.dc)
        fprintf(mfid,[changes{lineud.dc(j)},'\n']);
    end
end

% get ready to check on whether there is a second graph:
viewud = get(hand.viewmenu,'UserData');
ip = find(viewud==1);
plotV = 1;

if ~isempty(ip) % start first axes, dimensions almost those in SPLINETOOL
    fprintf(mfid,['firstbox = [0.1300  0.4900  0.7750  0.4850];\n',...
        'subplot(''Position'',firstbox)\n']);
end
fprintf(mfid, 'plot(x,y,''ok''), hold on\nnames={''data''};\n');
% also set the axes labels
fprintf(mfid, ['ylabel(''', ...
    strrep(get(get(hand.Axes(1),'YLabel'),'String'),'\','\\'),''')\n']);
if isempty(ip) % there is no second graph, hence
    fprintf(mfid, ['xlabel(''', ...
        strrep(get(get(hand.Axes(1),'XLabel'),'String'),'\','\\'),''')\n']);
else           % suppress also the tick marks on the first graph
    fprintf(mfid,'xtick = get(gca,''Xtick'');\nset(gca,''xtick'',[])\n');
end

switch length(vv)
    case 0
        fprintf(mfid,'\n%%  None of the fits you thought fit to print. \n\n');
        % we still may have to compute the current fit, though:
        if ~isempty(ip)
            vv = V;
            plotV=0;
        end
    case 1
        fprintf(mfid,sprintf('\n%%   %s\n\n',getString(message('SPLINES:resources:codegen_Plot'))));
    otherwise
        fprintf(mfid,sprintf('\n%%   %s \n\n',getString(message('SPLINES:resources:codegen_PlotMultiple',num2str(length(vv))))));
end

% loop over fits shown in graph, generating and plotting them, by
% first concatenating all relevant change commands

for v=vv
    lineud = get(listud.handles(v),'UserData');
    if datachanged % we have to start with the original data
        fprintf(mfid, 'x = x0; y = y0;\n');
    end
    % prepare optional arguments, if any
    [setknots,setweights,settols,ic] = iPrepareOptionalArguments(lineud);
    
    changes = get(hc,'UserData');
    for j=sort(ic)
        fprintf(mfid,[changes{j},'\n']);
    end
    
    bottom = lineud.bottom(2:end);
    % if there are no previous commands or if the last operation had to do
    % with knots or weights, then we still have to construct the spline fit
    if isempty(ic)||~(setknots||setweights||settols)||...
            (setknots&& ...
            ~(isempty(strfind(changes{lineud.kc(end)}, '\nknots ='))&&...
            isempty(strfind(changes{lineud.kc(end)}, '\nknots('))))||...
            (setweights&& ...
            ~(isempty(strfind( changes{lineud.wc(end)}, '\nweights ='))&&...
            isempty(strfind(changes{lineud.wc(end)}, '\nweights('))))||...
            (settols&& ...
            ~(isempty(strfind(changes{lineud.tc(end)}, '\ndlam ='))&&...
            isempty(strfind(changes{lineud.tc(end)}, '\ndlam('))))
        fprintf(mfid, [overlong(strrep(bottom,'%','%%')),'\n']);
    end
    
    % get the name of the spline fit
    name = bottom(1:(strfind( bottom(1:12), ' =' )-1));
    % add the name to the list to be used in the legend
    if v~=V||plotV
        fprintf(mfid, ['names{end+1} = ''',strrep(name,'_','\\_'),'''; ']);
    end
    % plot the spline fit, making certain to highlight the current one
    if v==V
        if plotV
            fprintf(mfid, ['fnplt(',name,',''','-',''',2)\n\n\n']); end
        
        % if there is a second figure, plot it now since we have the data
        %  code insert
        if ~isempty(ip)
            %start second axes, dimensions exactly those in SPLINETOOL
            iPrintCodeToStartSubplot(mfid, V==vv(end));
            
            switch ip
                case 1
                    fprintf(mfid,['fnplt(fnder(',hand.dbname,'),2)\n']);
                case 2
                    fprintf(mfid,['fnplt(fnder(',hand.dbname,',2),2)\n']);
                case 3
                    fprintf(mfid, ['plot(xtick([1 end]),zeros(1,2),',...
                        '''LineWidth'',2,''Color'',repmat(.6,1,3))\nhold on\n']);
                    if get(hand.dataline,'UserData') % if we compare against a given f
                        fprintf(mfid, ['%% ',getString(message('SPLINES:resources:codegen_CompareApproximation')),...
                            ',\n%% ',getString(message('SPLINES:resources:codegen_GivenFunction')),'\n',...
                            'xy = fnplt(',hand.dbname,');\nplot(xy(1,:),feval(''', ...
                            get(get(hand.Axes(1),'YLabel'),'String'),''',xy(1,:))', ...
                            '-xy(2,:),''LineWidth'',2)\n']);
                    else
                        fprintf(mfid,['plot(x,y-fnval(',hand.dbname, ...
                            ',x),''LineWidth'',2)\n']);
                    end
                    fprintf(mfid,'hold off\n');
            end %switch ip
            fprintf(mfid, ['ylabel(''', ...
                strrep(get(get(hand.Axes(2),'YLabel'),'String'),'\','\\'),''')\n', ...
                'xlabel(''', ...
                strrep(get(get(hand.Axes(2),'XLabel'),'String'),'\','\\'),''')\n', ...
                '\n\n%%   Return to plotting the first graph\n', ...
                'subplot(''Position'', firstbox)\n\n\n']);
        end
        %  end code insert
    else
        fprintf(mfid, ['fnplt(',name,...
            ',''',get(listud.handles(v),'LineStyle'),'k'')\n\n\n']);
    end
end

% also put in the legend
fprintf(mfid, 'legend(names{:});\n' );
fprintf(mfid, 'hold off\n' );
fprintf(mfid, 'set(gcf,''NextPlot'',''replace'');\n' );
end  % iGenerateCode


function iWriteComment( mfid, aMessage )
% iWriteComment   Write a comment to a file with long lines wrapped.
COMMENT_FORMAT = '%%   %s\n';
margin = 72;

comment = getString( aMessage );

sentenceSplitter = curvefit.SentenceSplitter();
sentences = sentenceSplitter.split(comment, margin);

fprintf( mfid, COMMENT_FORMAT, sentences{:} );
end  % iWriteComment

function iPrintCodeToStartSubplot(mfid, isLast)
addon = '\n\n';
if ~isLast
    addon = [getString(message('SPLINES:resources:codegen_DataCurrent')),addon];
end
fprintf(mfid, ...
    ['%%   ',getString(message('SPLINES:resources:codegen_Plot2ndGraph')),addon, ...
    'subplot(''Position'',[ 0.1300  0.1300  0.7750  0.3100])\n']);
end  % iPrintCodeToStartSubplot

function line = iCreateBottomLine( name, command, comment )
% iSetBottomLine   Create text for the bottom line
%
% Inputs
%   name   A string (char array) with the name of the variable on the left-hand
%       side of the bottom line
%   command   A string (char array) with the MATLAB command that goes on the
%       right hand side of the bottom line
%   comment   An array of messages that contain the comment to put on the bottom 
%       line.
%
% The bottom line will be
%       [name] = [command] % [comment]
START = ' '; 
EQUALS = ' = ';

commentString = iMessageToComment( comment );
line = [START, name, EQUALS, command, commentString];
end  % iCreateBottomLine

function commentString = iMessageToComment(comment)
COMMENT = ' % ';
   
if isempty( comment )
    commentString = '';
else
    % Build up comment text from array of messages
    commentString = [COMMENT, getString( comment(1) )];
    for i = 2:length( comment )
        commentString = sprintf( '%s; %s', commentString, getString( comment(i) ) );
    end
end
end % iMessageToComment

function hand = iLinkXLims(hand)
% make sure that the lower plot always has the same x axis limits as the
% upper plot
setXLim = @(src,evt)set(hand.Axes(2),'XLim', get(hand.Axes(1),'XLim'));
hand.XLimListener = addlistener( hand.Axes(1), 'MarkedClean', setXLim );
end


