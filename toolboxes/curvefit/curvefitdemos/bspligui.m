function bspligui(arg,topic)
%BSPLIGUI    Experiment with B-splines
%
%   BSPLIGUI opens B-spline GUI using the knot sequence -1:.5:1. Use the GUI to
%   experiment with how a B-spline depends on its knots. Click the Help Menu in
%   the GUI for detailed information.
%
%   BSPLIGUI(KNOTS) starts the GUI with the knot sequence KNOTS, but translated
%   and scaled to have -1 and 1 as the extreme knots.
%
%   BSPLIGUI('close') closes B-spline GUI. Clicking on the button marked Close
%   also closes the GUI
%
%   See also BSPLINE, SPCOL.

%   BSPLIGUI('exit'), BSPLIGUI('finish') and BSPLIGUI('quit') are alternative
%   ways to close B-spline GUI.

%   Copyright 1987-2012 The MathWorks, Inc.

v = ver('curvefit');
[relYear,~,~] = datevec(v.Date);
abouttext = {
    sprintf( '%s %s', v.Name, v.Version )
    sprintf( 'Copyright 1987-%d The MathWorks, Inc.', relYear )
    };

if nargin==0 % we are starting from scratch

   if ~isempty(findobj(allchild(0),'FileName','bspligui.m'))
      errordlg('BSPLIGUI is already running','No need to start another one ...')
      return
   end
   
   t = []; arg = 'start';

elseif  ischar(arg)
   hand = get(gcbf,'UserData');

else % we take arg to be a knot sequence to be used
   diffa = diff(arg);
   if isempty(diffa)||~any(diffa)
      errordlg('Need at least two distinct knots'), return
   end
   t = arg(:).';
   if any(diffa<0) % need to sort
      t = sort(t);
   end
   bspligui('exit'), arg = 'start';
   
end

switch arg

case 'add'
   
   [tadd,~] = ginput(1); 
   t = get(hand.shmarker,'XData');
   tadd = max(t(1),min(t(end),tadd));
   [t,index] = sort([tadd,t]);
   set(hand.shmarker,'XData',t)
   V = find(index==1);
   set(hand.shknots,'UserData',V,'XData',t([V V]))
   set(hand.shslider,'Value',t(V))
   if length(t)<4, set(hand.shknots,'Visible','on'), end

   bsplshw(t,hand)

case {'close','exit','finish','quit'}
   close(findobj(allchild(0),'FileName','bspligui.m'))

case 'delete' % delete the marked knot
   if strcmp(get(hand.shknots,'Visible'),'on')
      t = get(hand.shmarker,'XData');
      V = get(hand.shknots,'UserData'); 
      t(V)=[];
         ks = .07; % controls spacing for multiple knot display
      set(hand.shmarker,'XData',t,'YData',knt2mlt(t)*ks)
      if length(t)<3
         set(hand.shknots,'Visible','off','UserData',1)
      else
         V = min(V, length(t)-1);
         set(hand.shknots,'UserData', V, 'XData',t([V V]))
         set(hand.shslider,'Value',t(V))
      end
      bsplshw(t,hand)
   end

case 'help'

   titlestring = sprintf( 'Explanation: %s', topic );
   switch topic

   case 'about'
      titlestring = 'About Curve Fitting Toolbox';
      mess = abouttext;

   otherwise
      mess = spterms(topic);
   end

   msgbox(mess,titlestring)

case 'mark'  % action when one of the axes is clicked

   % only react here to LEFT clicks
   temp = get(gcbf,'SelectionType');
   if temp(1)=='n'

      % get the location of the latest click in data coordinates:
      clickp = get(gca,'CurrentPoint');
      
      % find the nearest interior knot, if any
      t = get(hand.shmarker,'XData');
      if length(t)>2
         [~,V] = min(abs(clickp(1,1)-t(2:end-1)));
         set(hand.shknots,'UserData',V+1,'XData',t([V+1 V+1]))
         set(hand.shslider,'Value',t(V+1))
      end
   end

case 'move'
   
   if strcmp(get(hand.shknots,'Visible'),'on') % only move if there are more
                                               % than two knots...
      t = get(hand.shmarker,'XData');
      told = t(get(hand.shknots,'UserData'));
      toldi = find(t==told); t(toldi) = []; others = length(toldi)-1;
      ta = max(hand.interv(1),min(hand.interv(2), get(hand.shslider,'Value')));
      [distance,j] = min(abs(ta-t));
      if distance < hand.tol, ta = t(j); end
      if get(hand.toggle,'Value') 
             % must make sure to leave an end behind
         tamore = repmat(ta,1,others);
         if any(hand.interv==told), tamore(end)=told; end
      else
         tamore = repmat(told,1,others);
      end
      [t,index] = sort([ ta, tamore, t]);
      V = find(index==1);
      set(hand.shknots,'UserData',V)
      set(hand.shslider,'Value',t(V))
      set(hand.shmarker,'XData',t)
      bsplshw(t,hand)
   end 

case 'start'

   if isempty(t), t = -1:.5:1;
   else  t = -1 +(2/(t(end)-t(1)))*(t-t(1));
   end
   lt = length(t);
   bspliguifig = figure('Color',[.8 .8 .8], ...
          'FileName','bspligui.m',...
          'Units','normalized', ...
          'Position',[.25 .10 .48 .75], ...
          'NumberTitle','off', ...
          'Name','Experiment with a B-spline as a function of its knots',...
          'MenuBar','none', ...
          'ToolBar','none');

   hand = struct('knotline',zeros(1,4), 'shder',zeros(1,4),'text',0, ...
                 'shmarker',0,'shknots',0,'shslider',0,'interv',[-1 1], ...
                 'tol',.01);
   ss = .225; % controls vertical spacing of displays
   ds = .02; % controls space between displays
   xs = .48; % controls left corner of displays
   dx = .48; % controls width of displays
   dxl = .044; % controls the needed OverWidth of the slider control
   dxr = .034; % controls the needed OverWidth of the slider control
   ys = .1; % controls bottom of displays
   lw = 2; % controls LineWidth used in displays
   lc = 'b'; % controls line color
   ks = .07; % controls spacing for multiple knot display
   axes('Position',[xs ys+3*ss dx ss-ds], ...
       'ButtonDownFcn','bspligui ''mark''', ...
       'FontSize',8, ...
       'XTickLabel',[]);
   hand.knotline(1) = line('XData',NaN,'YData',NaN,'Color',[.8 .8 .8], ...
              'LineWidth',2, ...
              'ButtonDownFcn','bspligui ''mark''');
   XX = linspace(hand.interv(1),hand.interv(2),101);
   hand.shder(1) = line('XData',XX,'YData',zeros(1, 101), ...
               'Color',lc,'LineWidth',lw);
   hand.shmarker = line(t,knt2mlt(t)*ks,'Marker','x','Color','r', ...
               'LineStyle','none', ...
               'UserData',ks);
   hand.shknots = line(t([2 2]),[0 1],'Color','r','LineWidth',2, ...
               'Visible','on', ...
               'UserData',2);
   if length(t)<3, set(hand.shknots,'Visible','off'), end
   axis([hand.interv(1), hand.interv(2), 0, 1]);
   vals = segplot([t;zeros(1,lt);t;ones(1,lt)]);
   set(hand.knotline(1),'XData',vals(1,:),'YData',vals(2,:))
   
   for j=2:4
      a = axes('Position',[xs ys+(4-j)*ss dx ss-ds],...
                 'ButtonDownFcn','bspligui ''mark''', ...
                 'FontSize',8);
      if j<4, set(a, 'XTickLabel',[]), end
      line(t([1 end]),[0 0],'Color','k','LineWidth',.5)
      hand.knotline(j) = line('XData',NaN,'YData',NaN,'Color',[.8 .8 .8], ...
                 'LineWidth',2, ...
                 'ButtonDownFcn','bspligui ''mark''');
      hand.shder(j) = line('XData',XX,'YData',zeros(1,101),'Color',lc, ...
                           'LineWidth',lw);
   end
   
   wl = .01; ww = .40; hh = .08;  dh = .02; lifts = .1;
   hand.text = uicontrol('Style','text', ...
     'Units','normalized','Position',[wl ys+3*ss ww ss-ds], ...
     'HorizontalAlignment','Left');
   uicontrol('Style','text', ...
     'Units','normalized','Position',[wl ys+3*ss-dh-hh ww hh], ...
     'String', ...
  'Also shown are the 1st, 2nd, and 3rd derivative of the B-spline.',...
     'HorizontalAlignment','Left');

   bsplshw(t,hand)
   
   hand.shslider = uicontrol('Style','Slider',...
        'Units','normalized','Position',[xs-dxl,.02,dx+dxl+dxr,.04], ...
        'Min',hand.interv(1),'Max',hand.interv(2),'Value',t(2),...
        'TooltipString','move the marked knot', ...
        'Callback', 'bspligui ''move''');
   uicontrol('Units','normalized','Position',[wl, lifts+4*(hh+dh), ww, hh], ...
        'String','Add a knot', ...
        'Callback', 'bspligui ''add''');
   uicontrol('Style','text', ...
        'Units','normalized','Position',[wl, lifts+3*(hh+dh), ww, hh], ...
        'String',{'';'Mark a knot by (left)clicking near it'});
   uicontrol('Units','normalized','Position',[wl, lifts+2*(hh+dh), ww, hh], ...
        'String','Delete the marked knot', ...
        'Callback', 'bspligui ''delete''');
   hand.toggle = uicontrol('Style','togglebutton', ...
        'Units','normalized','Position',[wl, lifts+(hh+dh), ww, hh], ...
        'String','Move the marked KNOT with the slider',...
        'TooltipString','toggle between moving knots and breaks', ...
        'Callback','bspligui ''toggle''','Value',0);
   uicontrol('Units','normalized','Position',[wl, lifts, ww, hh], ...
        'String','Close', ...
        'Callback', 'bspligui ''close''');

    % Construct help menu
    h1 = uimenu(gcf,'Label','&Help');
    uimenu(h1,'Label','&B-Spline GUI Help', ...
        'Tag', 'B-Spline-GUI-Help', ...
        'Callback','doc bspligui ');
    uimenu(h1,'Label','&Curve Fitting Toolbox Help', ...
        'Tag', 'B-Spline-GUI-Curvefit-Help', ...
        'Separator','on', ...
        'Callback', @iHelpCurvefitToolbox );
    uimenu(h1,'Label','Curve Fitting &Examples', ...
        'Tag', 'B-Spline-GUI-examples', ...
        'Callback','demo toolbox curve');
    uimenu(h1,'Label','&About',...
        'Tag', 'About-B-Spline-GUI', ...
        'Separator','on', ...
        'Callback','bspligui(''help'',''about'')');

   set(bspliguifig,'HandleVisibility','callback', 'UserData',hand)

case 'toggle'
   if get(hand.toggle,'Value')
      set(hand.toggle, 'String','Move the marked BREAK with the slider')
   else
      set(hand.toggle, 'String','Move the marked KNOT with the slider')
   end

otherwise
  error(message('SPLINES:BSPLIGUI:unknowninarg', arg))

end


function [pp4,k,l] = bsplget(t)
%BSPLGET values of a B-spline and its first three derivatives
%
%        [pp4,k,l] = bsplget(t)
%

pp = sp2pp(spmak(t,1));
%  put together values and first three derivatives, by first combining
%  values and second derivative, and then differentiating this to get
%  also first and third derivative
[breaks,coefs,l,k] = ppbrk(pp);
ddpp = fnder(pp,2);
if k>2
   pp2 = ...
     ppmak(breaks, reshape([coefs.';zeros(2,l);ppbrk(ddpp,'c').'],k,2*l).',2);
else
   pp2 = ppmak(breaks, reshape([coefs.';zeros(k,l)],k,2*l).',2);
end
if k>1
   pp4 = ppmak(breaks, ...
   reshape([ppbrk(pp2,'c').';zeros(1,2*l);ppbrk(fnder(pp2),'c').'],k,4*l).',4);
else
   pp4 = ppmak(breaks, ...
   reshape([ppbrk(pp2,'c').';zeros(1,2*l)],k,4*l).',4);
end

function bsplshw(t,hand)
%BSPLSHW redisplay b-spline and its derivatives

[pp4,k,l] = bsplget(t);
values = ppual(pp4,get(hand.shder(1),'XData'));

if l>1
    anzahl = sprintf( 'It consists of %s polynomial pieces, each of DEGREE %s.', num2str(l), num2str(k-1) );
else
    anzahl = sprintf( 'It consists of one polynomial piece of DEGREE %s.', num2str(k-1) );
end
theBSplineIsOfOrder = sprintf( 'The B-spline is of ORDER %s since it is specified by %s knots.', num2str(k), num2str(k+1) );
set(hand.text,...
    'String', {'',theBSplineIsOfOrder,'',anzahl}, ...
    'HorizontalAlignment','Left');

lt = length(t);
vals = segplot([t;zeros(1,lt);t;ones(1,lt)]);
set(hand.knotline(1),'XData',vals(1,:),'YData',vals(2,:))
set(hand.shder(1),'YData',values(1,:))
set(hand.shmarker,'XData',t, ...
                  'YData',knt2mlt(sort(t))*get(hand.shmarker,'UserData'))
set(hand.shknots,'XData',t(repmat(get(hand.shknots,'UserData'),1,2)))

for j=2:4
   set(hand.shder(j),'YData',values(j,:))
   vals = segplot([t;repmat(min(values(j,:))-.1,1,lt); ...
                   t;repmat(max(values(j,:))+.1,1,lt)]);
   set(hand.knotline(j),'XData',vals(1,:),'YData',vals(2,:))
end

function segsout = segplot(s, varargin ) 
%SEGPLOT plot a collection of segments
%
%        segsout = segplot(s,arg2,arg3)
%
%  returns the appropriate sequences  SEGSOUT(1,:) and  SEGSOUT(2,:)
% (containing the segment endpoints properly interspersed with NaN's)
% so that PLOT(SEGSOUT(1,:),SEGSOUT(2,:)) plots the straight-line 
% segment(s) with endpoints  (S(1,:),S(2,:))  and  (S(d+1,:),S(d+2,:)) ,
% with S of size  [2*d,:].
%
%  If there is no output argument, the segment(s) will be plotted in
% the current figure (and nothing will be returned),
% using the LineStyle and LineWidth optionally specified by ARG2 and ARG3 
% as a string and a number, respectively.

[twod,n] = size(s); d = twod/2;
if d<2, error(message('SPLINES:BSPLIGUI:inputwrongsize')), end
if d>2, s = s([1 2 d+1 d+2],:); end

tmp = [s; NaN(1,n)];
segs = [reshape(tmp([1 3 5],:),1,3*n);
        reshape(tmp([2 4 5],:),1,3*n)];

if nargout==0
   symbol=[]; linewidth=[];
   for j=2:nargin
      arg = varargin{j-1};
      if ischar(arg), symbol=arg;
      else
         [d,~]=size(arg);
         if d~=1
            error(message('SPLINES:BSPLIGUI:wronginarg', num2str( j )))
         else
            linewidth = arg;
         end
      end
   end
   if isempty(symbol) 
       symbol='-'; 
   end
   if isempty(linewidth) 
       linewidth=1; 
   end
   plot(segs(1,:),segs(2,:),symbol,'LineWidth',linewidth)
   % plot(s([1 3],:), s([2 4],:),symbol,'LineWidth',linewidth)
   % would also work, without all that extra NaN, but is noticeably slower.
else
   segsout = segs;
end

function iHelpCurvefitToolbox(~,~)
doc curvefit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  the end
