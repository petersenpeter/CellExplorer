function [points,t] = fnplt(f,varargin)
%FNPLT Plot a function.
%
%   FNPLT(F)  plots the function in F on its basic interval.
%
%   FNPLT(F,SYMBOL,INTERV,LINEWIDTH,JUMPS) plots the function F
%   on the specified INTERV = [a,b] (default is the basic interval),
%   using the specified plotting SYMBOL (default is '-'),
%   and the specified LINEWIDTH (default is 1),
%   and using NaNs in order to show any jumps as actual jumps only
%   in case JUMPS is a string beginning with 'j'.
%
%   The four optional arguments may appear in any order, with INTERV
%   the one of size [1 2], SYMBOL and JUMPS strings, and LINEWIDTH the
%   scalar. Any empty optional argument is ignored.
%
%   If the function in F is 2-vector-valued, the planar curve is
%   plotted.  If the function in F is d-vector-valued with d>2, the
%   space curve given by the first three components of F is plotted.
%
%   If the function is multivariate, it is plotted as a bivariate function,
%   at the midpoint of its basic intervals in additional variables, if any.
%
%   POINTS = FNPLT(F,...)   does not plot, but returns instead the sequence
%   of 2D-points or 3D-points it would have plotted.
%
%   [POINTS,T] = FNPLT(F,...)  also returns, for a vector-valued F, the
%   corresponding vector T of parameter values.
%
%   Example:
%      x=linspace(0,2*pi,21); f = spapi(4,x,sin(x));
%      fnplt(f,'r',3,[1 3])
%
%   plots the graph of the function in f, restricted to the interval [1 .. 3],
%   in red, with linewidth 3 .

%   Copyright 1987-2013 The MathWorks, Inc.

% interpret the input:
symbol='';
interv=[];
linewidth=[];
jumps=0;
for j=2:nargin
    arg = varargin{j-1};
    if ~isempty(arg)
        if ischar(arg)
            if arg(1)=='j',
                jumps = 1;
            else
                symbol = arg;
            end
        else
            [ignore,d] = size(arg);
            if ignore~=1
                error(message('SPLINES:FNPLT:wrongarg', num2str( j ))), end
            if d==1
                linewidth = arg;
            else
                interv = arg;
            end
        end
    end
end

% generate the plotting info:
if ~isstruct(f),
    f = fn2fm(f);
end

% convert ND-valued to equivalent vector-valued:
d = fnbrk(f,'dz');
if length(d)>1,
    f = fnchg(f,'dim',prod(d));
end

switch f.form(1:2)
    case 'st'
        if ~isempty(interv),
            f = stbrk(f,interv);
        else
            interv = stbrk(f,'interv');
        end
        npoints = 51;
        d = stbrk(f,'dim');
        switch fnbrk(f,'var')
            case 1
                x = linspace(interv{1}(1),interv{1}(2),npoints);
                v = stval(f,x);
            case 2
                x = {linspace(interv{1}(1),interv{1}(2),npoints), ...
                    linspace(interv{2}(1),interv{2}(2),npoints)};
                [xx,yy] = ndgrid(x{1},x{2});
                v = reshape(stval(f,[xx(:),yy(:)].'),[d,size(xx)]);
            otherwise
                error(message('SPLINES:FNPLT:atmostbivar'))
        end
    otherwise
        if ~strcmp(f.form([1 2]),'pp')
            givenform = f.form;
            f = fn2fm(f,'pp');
            basicint = ppbrk(f,'interval');
        end
        
        if ~isempty(interv),
            f = ppbrk(f,interv);
        end
        
        [breaks,l,d] = ppbrk(f,'b','l','d');
        if iscell(breaks)
            m = length(breaks);
            for i=m:-1:3
                x{i} = (breaks{i}(1)+breaks{i}(end))/2;
            end
            npoints = 51;
            ii = 1;
            if m>1,
                ii = [2 1];
            end
            for i=ii
                x{i}= linspace(breaks{i}(1),breaks{i}(end),npoints);
            end
            v = ppual(f,x);
            if exist('basicint','var')
                % we converted from B-form to ppform, hence must now
                % enforce the basic interval for the underlying spline.
                for i=ii
                    temp = find(x{i}<basicint{i}(1)|x{i}>basicint{i}(2));
                    if d==1
                        if ~isempty(temp),
                            v(:,temp,:) = 0;
                        end
                        v = permute(v,[2,1]);
                    else
                        if ~isempty(temp),
                            v(:,:,temp,:) = 0;
                        end
                        v = permute(v,[1,3,2]);
                    end
                end
            end
        else     % we are dealing with a univariate spline
            npoints = 101;
            x = [breaks(2:l) linspace(breaks(1),breaks(l+1),npoints)];
            v = ppual(f,x);
            if l>1 % make sure of proper treatment at jumps if so required
                if jumps
                    tx = breaks(2:l);
                    temp = NaN(d,l-1);
                else
                    tx = [];
                    temp = zeros(d,0);
                end
                x = [breaks(2:l) tx x];
                v = [ppual(f,breaks(2:l),'left') temp v];
            end
            [x,inx] = sort(x);
            v = v(:,inx);
            
            if exist('basicint','var')
                % we converted from B-form to ppform, hence must now
                % enforce the basic interval for the underlying spline.
                % Note that only the first d components are set to zero
                % outside the basic interval, i.e., the (d+1)st
                % component of a rational spline is left unaltered :-)
                if jumps,
                    extrap = NaN(d,1);
                else
                    extrap = zeros(d,1);
                    
                end
                temp = find(x<basicint(1));
                ltp = length(temp);
                if ltp
                    x = [x(temp),basicint([1 1]), x(ltp+1:end)];
                    v = [zeros(d,ltp+1),extrap,v(:,ltp+1:end)];
                end
                temp = find(x>basicint(2));
                ltp = length(temp);
                if ltp
                    x = [x(1:temp(1)-1),basicint([2 2]),x(temp)];
                    v = [v(:,1:temp(1)-1),extrap,zeros(d,ltp+1)];
                end
                %   temp = find(x<basicint(1)|x>basicint(2));
                %   if ~isempty(temp), v(temp) = zeros(d,length(temp)); end
            end
        end
        
        if exist('givenform','var')&&givenform(1)=='r'
            % we are dealing with a rational fn:
            % need to divide by last component
            d = d-1;
            sizev = size(v);
            sizev(1) = d;
            % since fnval will replace any zero value of the denominator by 1,
            % so must we here, for consistency:
            v(d+1,v(d+1,:)==0) = 1;
            v = reshape(v(1:d,:)./repmat(v(d+1,:),d,1),sizev);
        end
end

%  use the plotting info, to plot or else to output:
if nargout==0
    if iscell(x)
        switch d
            case 1
                [yy,xx] = meshgrid(x{2},x{1});
                surf(xx,yy,reshape(v,length(x{1}),length(x{2})))
            case 2
                v = squeeze(v);
                roughp = 1+(npoints-1)/5;
                vv = reshape(cat(1,...
                    permute(v(:,1:5:npoints,:),[3,2,1]),...
                    NaN([1,roughp,2]),...
                    permute(v(:,:,1:5:npoints),[2,3,1]),...
                    NaN([1,roughp,2])), ...
                    [2*roughp*(npoints+1),2]);
                plot(vv(:,1),vv(:,2))
            case 3
                v = permute(reshape(v,[3,length(x{1}),length(x{2})]),[2 3 1]);
                surf(v(:,:,1),v(:,:,2),v(:,:,3))
            otherwise
        end
    else
        if isempty(symbol),
            symbol = '-';
        end
        if isempty(linewidth),
            linewidth = 2;
        end
        switch d
            case 1,
                plot(x,v,symbol,'LineWidth',linewidth)
            case 2,
                plot(v(1,:),v(2,:),symbol,'LineWidth',linewidth)
            otherwise
                plot3(v(1,:),v(2,:),v(3,:),symbol,'LineWidth',linewidth)
        end
    end
else
    if iscell(x)
        switch d
            case 1
                [yy,xx] = meshgrid(x{2},x{1});
                points = {xx,yy,reshape(v,length(x{1}),length(x{2}))};
                iErrorSecondOutputForVectorValued( nargout );
            case 2
                [yy,xx] = meshgrid(x{2},x{1});
                points = {xx,yy,reshape(v,[2,length(x{1}),length(x{2})])};
                iErrorSecondOutputForVectorValued( nargout );
            case 3
                points = {squeeze(v(1,:)),squeeze(v(2,:)),squeeze(v(3,:))};
                t = {x{1:2}};
            otherwise
                iErrorSecondOutputForVectorValued( nargout );
        end
    else
        if d==1,
            points = [x;v];
            iErrorSecondOutputForVectorValued( nargout );
        else
            t = x;
            points = v(1:min([d,3]),:);
        end
    end
end

function iErrorSecondOutputForVectorValued( numArgOut )
if numArgOut >= 2
    exception = MException( 'SPLINES:FNPLT:SecondOutputForVectorValued', ...
        'Second output argument only supported for vector-valued F.' );
    throwAsCaller( exception );
end
