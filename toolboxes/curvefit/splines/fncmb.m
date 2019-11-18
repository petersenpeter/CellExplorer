function fn = fncmb(fn1,fnorsc,fn2,sc2)
%FNCMB Arithmetic with function(s).
%
%   FNCMB(function,operation) operation applied to function; specifically:
%     FNCMB(function,scalar)    multiplies function by scalar,
%     FNCMB(function,vector)    translates function value by vector,
%         (if function is scalar-valued, use
%         FNCMB(function,'+',scalar) to translate function value by scalar)
%     FNCMB(function,matrix)    applies matrix to coefficients of function.
%     FNCMB(function,string)    applies the function specified by string to
%                               coefficients of function.
%
%   FNCMB(function,function)  sum of the  two  functions of same form
%   FNCMB(function,matrix,function)  same as
%                        FNCMB(fncmb(function,matrix),function)
%   FNCMB(function,matrix,function,matrix)  same as
%                        FNCMB(fncmb(function,matrix),fncmb(function,matrix))
%
%   FNCMB(function,op,function)  ppform of the sum (op is '+'), difference
%                             (op is '-'), or pointwise product (op is '*') of
%                             the two functions possibly of different forms.
%                             In particular, in case of addition/subtraction,
%                             the second function may be just a point in the
%                             target of the first (i.e., a constant function).
%
%   At present, all functions must be UNIVARIATE except for the call
%   FNCMB(function,operation).
%
%   Examples:
%
%      fncmb( sp1, '+', sp2 );
%
%   returns the (pointwise) sum of the function in SP1 and that in SP2, while
%
%      fncmb( spmak( augknt(4:9,4), eye(8) ), [1:8] )
%
%   is a complicated way to construct sum_{j=1:8} j*B_j for the eight cubic
%   B-splines B_j for the knot sequence AUGKNT(4:9,4).
%
%   If SP contains a spline in B-form, then
%
%      spa = fncmb( sp, 'abs' );
%
%   changes all its coefficients to their absolute value.
%
%   If FN contains a 3-vector-valued function (i.e., a map into R^3), then
%
%      fncmb( fn, [1 0 0; 0 0 1] )
%
%   provides the projection onto the (x,z)-plane, while
%
%      fncmb( fncmb (fn, [1 0 0; 0 0 -1; 0 1 0] ), [1;2;3] )
%
%   rotates the image of the function in FN 90 degrees around the x-axis and
%   then translates that by the vector (1,2,3).

%   Copyright 1987-2010 The MathWorks, Inc.

if nargin<2, fn = fn1; return, end

if ~isstruct(fn1)
    try
        fn1 = fn2fm(fn1);
    catch ignore
        error(message('SPLINES:FNCMB:unknownfrstfn'))
    end
end

try
    fn1form = fnbrk(fn1,'form');
catch ignore
    error(message('SPLINES:FNCMB:unknownfrstfn'))
end

if nargin==2&&~isstruct(fnorsc) % we are to apply the operation specified
    % by FNORSC to the coefficients of FN1
    fn1form(3:end) = [];
    [coefs,d] = fnbrk(fn1,'coefs','dim');
    sizeval = d; if length(d)>1,  d = prod(d); end
    if ischar(fnorsc) %the operation is given by some function
        eval(['coefs = ',fnorsc,'(coefs);'])
    elseif length(fnorsc)==1% we multiply the coefficients by the scalar FNORSC
        switch fn1form
            case {'rp','rB'} % in rational case, only multiply the numerator
                coefs(1:d,:) = fnorsc*coefs(1:d,:);
            otherwise
                coefs = fnorsc*coefs;
        end
    else %FNORSC is either an array with more dimensions than fn1.dim and
        % with its last dimensions matching exactly fn1.dim;
        % or the first dimensions of FNORSC exactly match fn1.dim and the rest
        % are trivial; anything else is an error.
        sizesc = size(fnorsc);
        % will have to deal with the problem of vanishing unit dimensions
        diffl = length(sizesc)-length(sizeval);
        if diffl>0&&isequal(sizesc(diffl+1:end),sizeval)
            % we are to apply the `matrix' FNORSC to the coefficients
            sizeval = sizesc(1:diffl); r = prod(sizeval);
            fnorsc = reshape(fnorsc,r,d);
            sizec = size(coefs);
            l = 1;
            if fn1form(2)=='p'
                l = fnbrk(fn1,'pieces');
                if length(l)>1, l = 1; end
            end
            coefs = reshape(coefs,sizec(1)/l,l*prod(sizec(2:end)));
            switch fn1form
                case {'rB','rp'}
                    coefs = reshape([fnorsc*coefs(1:d,:); coefs(d+1,:)], ...
                        [(r+1)*l,sizec(2:end)]);
                otherwise
                    coefs = reshape(fnorsc*coefs,[r*l,sizec(2:end)]);
            end
            d = r;
        elseif prod(sizesc)==d&&...
                ((diffl>=0&&isequal(sizesc(1:length(sizeval)),sizeval))||...
                (diffl<0&&isequal(sizesc,sizeval(1:length(sizec)))))
            % we are to translate the appropriate coefficients by FNORSC
            fnorsc = reshape(fnorsc,d,1);
            switch fn1form
                case {'rB','rp'}
                    l = 1;
                    if fn1form(2)=='p'
                        l = fnbrk(fn1,'pieces');
                        if length(l)>1, l = 1; end
                    end
                    sizec = size(coefs); ncoefs = l*prod(sizec(2:end));
                    coefs = reshape(coefs,sizec(1)/l,ncoefs);
                    coefs(1:d,:) = repmat(fnorsc,1,ncoefs).* ...
                        repmat(coefs(d+1,:),d,1) + ...
                        coefs(1:d,:);
                    coefs = reshape(coefs,sizec);
                case 'pp'         % now only the constant terms get translated.
                    % In this case, the matrix COEFS is, equivalently,
                    % an array, of size [d,l1*k1,...,lm*km], with
                    % m>1 the dimension of the domain of the function.
                    % This means that FNORSC is added to each column of
                    % COEFS(:,(1:l1)*k1,...,(1:lm)*km). Our problem is
                    % that  m  is a variable. We take the coward's way
                    % out: a loop.
                    % Another complication: for m==1, COEFS is of size
                    % [d*l,k].
                    k = fnbrk(fn1,'order'); l = fnbrk(fn1,'pieces');
                    m = length(k); len(m:-1:1) = cumprod(l(m:-1:1));
                    index = (k(m)-1)*l(m)+(1:l(m)).';
                    for j=m-1:-1:1
                        index = reshape(repmat((l(j)*k(j))*(index-1),1,l(j)) + ...
                            repmat((k(j)-1)*l(j)+(1:l(j)),len(j+1),1),len(j),1);
                    end
                    prodk = prod(k);
                    coefs = reshape(coefs,d,len(1)*prodk);
                    coefs(:,index) = coefs(:,index) + repmat(fnorsc,1,len(1));
                    if m>1
                        coefs = reshape(coefs,[d,l.*k]);
                    else
                        coefs = reshape(coefs,d*l,k);
                    end
                    
                case {'B-','BB'}
                    coefs = coefs + repmat(fnorsc,[1,fnbrk(fn1,'number')]);
                case 'st' % in this case, only the coefficient of the constant term
                    % gets translated, i.e., the last coefficient
                    % (this is no good for 'st-tp' ...):
                    coefs(:,end) = coefs(:,end) + fnorsc;
            end
        else
            error(message('SPLINES:FNCMB:unknownsecfn'))
        end
    end
    % generate fn to be of the same form as fn1
    switch fn1form
        case 'pp'
            breaks = fnbrk(fn1,'breaks');
            if iscell(breaks)
                fn = ppmak(breaks,coefs, ...
                    [size(coefs,1),fnbrk(fn1,'pieces').*fnbrk(fn1,'order')]);
            else
                fn = ppmak(breaks,coefs,d);
            end
        case {'B-','BB'}
            fn = spmak(fnbrk(fn1,'knots'),coefs,[size(coefs,1),fnbrk(fn1,'number')]);
            fn.form = fn1.form;
        case 'rB'
            fn = rsmak(fnbrk(fn1,'knots'),coefs,[size(coefs,1),fnbrk(fn1,'number')]);
        case 'rp'
            breaks = fnbrk(fn1,'breaks');
            if iscell(breaks)
                fn = rpmak(breaks,coefs, ...
                    [size(coefs,1),fnbrk(fn1,'pieces').*fnbrk(fn1,'order')]);
            else
                fn = rpmak(breaks,coefs,d);
            end
        case 'st'
            fn = stmak(fnbrk(fn1,'centers'),coefs,fn1.form(4:end), ...
                fnbrk(fn1,'interv'));
        otherwise
            % cannot happen since the earlier fnbrk(fn1,'coefs') would have failed
            error(message('SPLINES:FNCMB:impossible'))
    end
    if length(sizeval)>1, fn = fnchg(fn,'dz',sizeval); end
    return
end

if fnbrk(fn1,'var')>1&&(nargin>2||(nargin==2&&isstruct(fnorsc)))
    error(message('SPLINES:FNCMB:onlyuni'))
end

if ischar(fnorsc) % we are in the case fn1 'op' fn2, with 'op' +-* and the
    % two functions of possibly different forms.
    if length(fnorsc)~=1||~any('+-*'==fnorsc)
        error(message('SPLINES:FNCMB:unknownop', fnorsc))
    end
    if nargin~=3
        error(message('SPLINES:FNCMB:needthree'))
    end
    
    if ~isstruct(fn2)
        try fn2 = fn2fm(fn2);% check whether FN2 is a function written the old way
        catch ignore %#ok<NASGU>
            % otherwise, FN2 must be a point in FN1's target
            % must ascertain that the constant FN2 is in the target of FN1
            % or else a scalar (in which case it will be taken to be the
            % corresponding constant element in the target of FN1).
            sizeval = fnbrk(fn1,'dim'); d = prod(sizeval); fn2 = fn2(:);
            if length(fn2)>1 && length(fn2)~=prod(sizeval)
                error(message('SPLINES:FNCMB:constwrongsize'))
            end
            switch fnorsc
                case '*'
                    if length(fn2)==1, fn = fncmb(fn1,fn2); clear sizeval
                    else % as a quickie, handle pointwise multiplication as matrix mult
                        fn = fncmb(fn1,reshape(diag(fn2), [sizeval,sizeval]));
                    end
                    
                otherwise  % it's addition of a constant and, since we can't be sure
                    % that the relevant B-splines form a partition of unity,
                    % it's easiest just to convert to ppform and then operate
                    % on the constant coefficients.
                    if strcmp(fn1form(1:2),'st')
                        error(message('SPLINES:FNCMB:notforst'))
                    end
                    if d>1&&length(fn2)==1, 
                        fn2 = repmat(fn2,d,1); 
                    end
                    if fn1form(1)=='r'
                        if fn1form(2)=='B',
                            fn1 = fn2fm(fn1,'rp'); 
                        end
                        [breaks,c,l,k,d] = ppbrk(fn2fm(fn1,'pp')); d = d-1;
                        % s/w + c = (c*w+s)/w
                        temp = reshape(c,[d+1,l,k]);
                        eval(['temp(1:d,:) = temp(1:d,:)',fnorsc,'fn2*temp(d+1,:);'])
                        fn = rpmak(breaks,reshape(temp, (d+1)*l,k),d);
                    else
                        if fn1form(1)=='B', 
                            fn1 = sp2pp(fn1); 
                        end
                        [breaks,c,l,k] = ppbrk(fn1);
                        %tmp = reshape(1:d,d,1); tmp = reshape(tmp(:,ones(1,l)),d*l,1);
                        tmp = reshape(repmat(reshape(1:d,d,1),1,l),d*l,1);
                        eval(['c(:,k) = c(:,k)',fnorsc,'fn2(tmp);'])
                        fn = ppmak(breaks,c,d);
                    end
            end
            if exist('sizeval','var')&&length(sizeval)>1
                fn = fnchg(fn,'dz',sizeval);
            end
            return
        end
    end
    
    %  else,  convert both FN1 and FN2 to ppform, if need be.
    
    % know from earlier test that fn2 is struct; now check that it is
    % actually a form we know:
    try
        fn2form = fnbrk(fn2,'form');
    catch ignore 
        error(message('SPLINES:FNCMB:unknownsecfun'))
    end
    
    % at present, this does not work for the stform
    if isequal(fn1form(1:2),'st')||isequal(fn2form(1:2),'st')
        error(message('SPLINES:FNCMB:notforstform'))
    end
    
    % next, establish the basic interval of the result as the smallest
    % interval containing both basic intervals and extend both fns to it.
    intervs = [fnbrk(fn1,'interv'); fnbrk(fn2,'interv')];
    interv = [min(intervs(:,1)), max(intervs(:,2))];
    fn1 = fnbrk(fn1,interv); fn2 = fnbrk(fn2,interv);
    
    %  next, convert rationals to their equivalent pp-version
    if fn1form(1)=='r', 
        fn1 = fn2fm(fn1,'pp'); 
    end
    if fn2form(1)=='r', 
        fn2 = fn2fm(fn2,'pp'); 
    end
    
    if fn1form(1)=='B', 
        fn1 = sp2pp(fn1); 
    end
    if fn2form(1)=='B', 
        fn2 = sp2pp(fn2); 
    end
    
    % establish the common refinement of the two break sequences
    tmp = sort([ppbrk(fn1,'b') ppbrk(fn2,'b')]);
    breaks = tmp([find(diff(tmp)>0),end]);
    % refine breaks in both FN1 and FN2
    fn1 = pprfn(fn1,breaks); fn2 = pprfn(fn2,breaks);
    [~,c1,l1,k1,d1] = ppbrk(fn1);
    [~,c2,l2,k2,d2] = ppbrk(fn2);
    if (fnorsc=='+'||fnorsc=='-')
        if fn1form(1)=='r'||fn2form(1)=='r'
            % c1 = reshape(c1,[d1,l1,k1]); c2 = reshape(c2,[d2,l2,k2]);
            k = k1+k2-1;
            if fn1form(1)~='r' % only the second is rational
                if d1~=d2-1
                    error(message('SPLINES:FNCMB:targetsdontmatch'))
                end
                % s1 op s2/w2 = (s1*w2 op s2)/w2
                c = reshape([zeros(d2*l2,k1-1),c2],[d2,l2,k]);
                temp =matconv(c1,reshape(repmat(c(d2,:,k1:end),[d1,1,1]),d1*l1,k2));
                eval(['c(1:d1,:,:) = reshape(temp,[d1,l1,k])',fnorsc, ...
                    'c(1:d1,:,:);'])
                d1 = d1+1;
            elseif fn2form(1)~='r' % only the first is rational
                if d1-1~=d2
                    error(message('SPLINES:FNCMB:targetsdontmatch'))
                end
                % s1/w1 op s2 = (s1 op s2*w1)/w1
                c = reshape([zeros(d1*l1,k2-1),c1],[d1,l1,k]);
                temp =matconv(c2,reshape(repmat(c(d1,:,k2:end),[d2,1,1]),d2*l2,k1));
                eval(['c(1:d2,:,:) = c(1:d2,:,:)',fnorsc, ...
                    'reshape(temp,[d2,l2,k]);'])
            else                   % both are rational
                c1 = reshape(c1,[d1,l1,k1]); c2 = reshape(c2,[d2,l2,k2]);
                if d1~=d2
                    error(message('SPLINES:FNCMB:targetsdontmatch'))
                end
                % s1/w1 op s2/w2 = (s1*w2 op s2*w1)/(w1*w2)
                c = zeros([d1,l1,k]); d = d1-1;
                eval(['c(1:d,:,:)=reshape(matconv(reshape(c1(1:d,:,:),d*l1,k1)',...
                    ',reshape(repmat(c2(d1,:,:),[d,1,1]),d*l2,k2))', fnorsc, ...
                    'matconv(reshape(c2(1:d,:,:),d*l2,k2)',...
                    ',reshape(repmat(c1(d1,:,:),[d,1,1]),d*l1,k1)),[d,l1,k]);'])
                c(d1,:,:) = reshape(matconv(reshape(c1(d1,:,:),l1,k1), ...
                    reshape(c2(d1,:,:),l2,k2)),[1,l1,k]);
            end
        else
            if d1~=d2
                error(message('SPLINES:FNCMB:targetsdontmatch'))
            end
            k = k1;
            if k1<k2, k = k2; c1 = [zeros(d1*l1,k2-k1) c1];
            elseif k1>k2, c2 = [zeros(d2*l2,k1-k2) c2]; end
            eval(['c = c1',fnorsc,'c2;'])
        end
        c = reshape(c,[d1*l1,k]);
    else  % we pointwise multiply:
        k = k1+k2-1;
        if (fn1form(1)=='r'&&fn2form(1)=='r')||(fn1form(1)~='r'&&fn2form(1)~='r')
            c = matconv(c1,c2);
        else
            if fn1form(1)=='r'
                if d1-1~=d2
                    error(message('SPLINES:FNCMB:targetsdontmatch'))
                end
                c = reshape([zeros(d1*l1,k2-1),c1],[d1,l1,k]);
                c(1:d2,:,:) = reshape(...
                    matconv(reshape(c(1:d2,:,k2:end),d2*l1,k1),c2), ...
                    [d2,l1,k]);
                c = reshape(c,[d1*l1,k]);
            else
                if d1~=d2-1
                    error(message('SPLINES:FNCMB:targetsdontmatch'))
                end
                c = reshape([zeros(d2*l2,k1-1),c2],[d2,l2,k]);
                c(1:d1,:,:) = reshape(...
                    matconv(reshape(c(1:d1,:,k1:end),d1*l2,k2),c1), ...
                    [d1,l2,k]);
                c = reshape(c,[d2*l2,k]);
                d1 = d1+1;
            end
        end
    end
    if fn1form(1)=='r'||fn2form(1)=='r'
        fn = rpmak(breaks,c,d1-1);
    else
        fn = ppmak(breaks,c,d1);
    end
    return
end

%%%%%%%  at this point, we know that  FNORSC  is a matrix (iff nargin>2)
%  or a function (iff nargin==2)

% reduce it to the case of adding fn1 and fn2
if nargin==2
    fn2 = fnorsc;
else
    fn1 = fncmb(fn1,fnorsc);
    if nargin>3
        fn2 = fncmb(fn2,sc2);
    end
end

try
    coefs2 = fnbrk(fn2,'c');
catch ignore
    error(message('SPLINES:FNCMB:unknownsecfn'))
end

if ~isequal(fn1form,fnbrk(fn2,'form'))
    error(message('SPLINES:FNCMB:formsdontmatch'))
end

switch fn1form(1)
    case 'B'
        [knots,coefs] = spbrk(fn1);
        fn = spmak(knots,sumcoefs(coefs,coefs2));
    case 'p'
        [breaks,coefs,l,k,d] = ppbrk(fn1);
        coefs = sumcoefs(coefs,coefs2);
        if length(k)>1
            fn = ppmak(breaks,coefs);
        else
            fn = ppmak(breaks,coefs,[d,l,k]);
        end
        
    case 'r'
        
        switch fn1form(2)
            case 'B'
                knots = fnbrk(fn1,'knots'); c1 = fnbrk(fn1,'coefs');
                if any(size(c1)-size(coefs2))
                    fn = fncmb(fn1,'+',fn2);
                else
                    dw = c1(end,:)-coefs2(end,:);
                    if max(abs(dw))>1e-12*max(abs(c1(end,:)))
                        fn = fncmb(fn1,fn2);
                    else
                        c1(1:end-1,:) = c1(1:end-1,:)+coefs2(1:end-1,:);
                        fn = rsmak(knots, c1);
                    end
                end
            case 'p'
                fn = fncmb(fn1,'+',fn2);
            otherwise
                error(message('SPLINES:FNCMB:unknownfrstfn'))
        end
    otherwise
        error(message('SPLINES:FNCMB:unknownfrstfn'))
end

function asb = matconv(a,b)
%MATCONV row-by-row convolution of the two matrices a and b
%
% asb(j,:) = conv(a(j,:),b(j,:)), all j
%
% An error will occur if a and b fail to have the same number of rows.

[ra,ca] = size(a); cb = size(b,2);

% make sure that a is the one with fewer columns
if ca>cb
    temp = b; b = a; a = temp; temp = ca; ca = cb; cb = temp;
end

asb = zeros(ra,ca+cb-1);
for j=1:ca
    asb(:,j-1+(1:cb)) = asb(:,j-1+(1:cb))+repmat(a(:,j),1,cb).*b;
end

function coefs = sumcoefs(coef1,coef2)
%SUMCOEFS if sizes of coef1,2 match, return sum; else, print error message

if ~isequal(size(coef1),size(coef2))
    error(message('SPLINES:FNCMB:incompatiblecoefs'))
end
coefs = coef1 + coef2;
