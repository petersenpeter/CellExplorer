function z = fnzeros(f,interv)
%FNZEROS Find zeros of a function in given interval
%
%   Z = FNZEROS(F,[A B]) is an ordered list of the zeros of the univariate
%   spline F in the interval [A .. B]. 
%
%   Z = FNZEROS(F) is a list of the zeros in the basic interval of the spline F.
%
%   A spline zero is either a maximal closed interval over which the spline is
%   zero or a zero crossing (a point across which the spline changes sign). 
%
%   The list of zeros, Z, is a matrix with two rows, the first row is the left
%   endpoint of the intervals and the second row is the right endpoint. Thus,
%   each column Z(:,J) contains the left and right endpoint of a single
%   interval. These intervals are of three kinds:   
%
%   * If the endpoints are different, then the function is zero on the entire
%   interval. In this case the maximal interval is given, regardless of knots
%   that may be in the interior of the interval.  
% 
%   * If the endpoints are the same and coincident with a knot, then the
%   function in f has a zero at that point. The spline could cross zero, touch
%   zero or be discontinuous at this point.  
%
%   * If the endpoints are the same and not coincident with a knot, then the
%   spline has a zero crossing at this point. 
%
%   If the spline, F, touches zero at a point that is not a knot but does not
%   cross zero, then this zero may not be found. If it is found, then it may be
%   found twice.  
%
%   Examples:
%   The quadratic polynomial (x-1)^2 =x^2-2*x+1  has a double zero at x = 1;
%   correspondingly, the command
%
%      fnzeros( ppmak( [0 2.1], [1 -2 1] ) )
%
%   returns a matrix that is nearly ones(2,2). 
%
%   Because the minimum of a univariate scalar function must be at a zero of its
%   derivative or at the ends of the interval of interest, we can use FNZEROS to
%   find the minimum value of a spline. For example,
%
%      % An example spline
%      f = spmak( 1:21, rand( 1, 15 )-0.5 ); 
%      % The interval of interest is the basic interval
%      interval = fnbrk( f, 'interval' );
%      % Find zeros of the derivative
%      z = fnzeros( fnder( f ) );
%      % Because f and its derivative have no repeated knots, the zeros can
%      % only be points
%      z = z(1,:);
%      % Evaluate the spline at the ends of the basic interval and the zeros of
%      % the derivative.
%      values = fnval( f, [interval, z] );
%      % The minimum of these values is the minimum value of the spline.
%      min( values )
%
%   See also FNVAL, FNMIN.

% References
%   [MR07] Knut Morken and Martin Reimers, "An unconditionally convergent
%       method for computing zeros of splines and polynomials", Math. Comp
%       76:845--865, 2007.

%   Copyright 1987-2010 The MathWorks, Inc.

if fnbrk(f,'var')>1
    error(message('SPLINES:FNZEROS:onlyuni'))
end

if nargin>1&&~isempty(interv)
    f = fnbrk(f,interv);
end

d = fnbrk(f,'dim');
if length(d)>1||d>1
    error(message('SPLINES:FNZEROS:onlyscalar'))
end

f = fn2fm(f,'B-'); % make sure the function is in B-form

[k, coefs, knots] = fnbrk( f, 'order', 'coefs', 'knots' );
if size(coefs,1)>1     %  since f is scalar-valued, it must be rational;
    coefs = coefs(1,:); %  so, look only at the numerator.
    f = spmak( knots, coefs );
end

% deal directly with the special case that f is the zero function
if ~any(coefs)
    z = fnbrk(f,'interv').';
    return
end

scoefs = sign(coefs);

% Deal with the fact that, if F is in B-form, then it may vanish at the
% endpoints of its basic interval without having zero coefficients there.
if scoefs(1)&&~fnval(f,knots(1))
    knots = knots([1,1:end]); scoefs = [0,scoefs]; coefs = [0,coefs];
end
if scoefs(end)&&~fnval(f,knots(end))
    knots = knots([1:end,end]); scoefs = [scoefs,0]; coefs = [coefs,0];
end

% deal directly with the special case that all coefs are of one sign
if all(scoefs>0)||all(scoefs<0)
    z = zeros(2,0);
    return
end

% Look for runs of consecutive zeros
[temp, lengths] = iFindConsecutiveZeros( coefs );

zints = zeros(2,0);
% check for an initial zero
zfirst = zeros(2,0);
if scoefs(1) == 0
    lastz = temp(1)+1;
    temp(1)=[];
    lengths(1)=[];
    zfirst = knots([1 lastz]).';
    scoefs(1:lastz-1) = scoefs(lastz);
end
zfinal = zeros(2,0);
if ~isempty(temp)
    % check for a final zero
    if ~scoefs(end)
        zfinal = knots([end-lengths(end) end]).';
        scoefs(end-lengths(end)+1:end) = scoefs(end-lengths(end));
        temp(end)=[];
        lengths(end)=[];
    end
    % deal with zero intervals, if any:
    ints = find(lengths>k-1);
    if ~isempty(ints)
        zints = [knots(temp(ints)-lengths(ints)+k);knots(temp(ints)+1)];
    end
    % remove all intervals of length 0; these zeros will be found by the
    % adapted morken algorithm
    zints(:,zints(1,:)==zints(2,:)) = [];
end

zints = [zfirst zints zfinal];
% At this point, the only zeros not yet identified are point zeros.

% First, search out and remove sign changes across knots of maximum
% multiplicity (which can happen only for discontinuous splines)

[~,mults] = knt2brk(knots);
% Find knots of max multiplicity
index_max_mult = find( mults==k );
% ... but ignore the first and last knots
if mults(1)==k;
    index_max_mult(1) = [];
end
if mults(end)==k;
    index_max_mult(end) = [];
end

if ~isempty(index_max_mult)
    
    index_of_end_of_break = cumsum( mults );
    index_of_end_of_max_mult_break = index_of_end_of_break(index_max_mult);
    index_of_break_before_max_mult = index_of_end_of_max_mult_break - k;
    
    is_sign_change_at_max_mult = abs( ...
        scoefs(index_of_break_before_max_mult+1) - ...
        scoefs(index_of_break_before_max_mult) ...
        ) > 1;
    
    
    if any( is_sign_change_at_max_mult )
        
        index_of_sign_change_zero = 1 + index_of_break_before_max_mult(is_sign_change_at_max_mult);
        
        signChangeZeros = knots([1 1],index_of_sign_change_zero);
        % Add any zeros found to the list of intervals we have already found
        if ~isempty(zints)
            zints = [zints signChangeZeros];
            % ... and ensure that we keep the zeros sorted
            [~, ii] = sort(zints(1,:));
            zints = zints(:,ii);
        else
            zints = signChangeZeros;
        end
        
        % At each sign change zero, negate the coefficients to the right of the
        % corresponding knot. The resulting spline then does not have a sign
        % change at these points but any other zero is unaffected
        for j=index_of_sign_change_zero
            coefs(:,j:end) = -coefs(:,j:end);
        end
        f = spmak(knots,coefs);
        
    end
end

% If the spline is piecewise constant, then we have found all possible zeros.
if k < 2,
    z = zints;
    return
end

% Use the Morken algorithm to find the zero points of the spline
moreZeros = iFindZeros_Morken(f);

% Combine all the zeros
z = horzcat( moreZeros([1 1],:), zints );

% Sort the zeros based (arbitrarily) on the start points of the intervals
[~, idx] = sort( z(1,:) );
z = z(:,idx);

end

function [index, lengths] = iFindConsecutiveZeros( coefs )
% iFindConsecutiveZeros -- finds the indices of the end of a run of consecutive
% zeros.
%
% The length of each run is also returned.
%
% The vectors index and lengths are the same size.
mults = knt2mlt( cumsum( [0, coefs ~= 0] ) );
mults(1) = [];

% for all j>1 and all 0<=r<mults(j), coefs(j-r)==0, hence each entry of
index = find( diff( mults ) < 0);
% ... indicates the end of a run of consecutive zeros
% except that this misses the run at the end of coefs (if any)
if coefs(end) == 0,
    index(end+1) = length(coefs);
end

% Save the multiplicities as lengths
lengths = mults(index);

end

function theZeros = iFindZeros_Morken( theSpline )
% iFindZeros_Morken -- find point zeros of a spline
%   This function implements that Morken & Reimers algorithm for finding zeros
%   of a (connected continuous) spline [MR07] but applied to a possibly
%   discontinuous spline from which all jumps through 0 have been removed.
%

k = fnbrk( theSpline, 'order' );
zeroTracker = iZeroTracker( k );

while ~zeroTracker.IsConverged()
    % Find zeros of control polygon
    controlZeros = iZerosOfControlPolygon( theSpline );
    
    % Do any of these zeros correspond to knots of maximum multiplicity?
    knots = fnbrk( theSpline, 'knots' );
    [breaks, mult] = knt2brk( knots );
    knotsOfMaxMultiplicty = breaks(mult>=k);
    
    isZeroOfMaxMultiplicty = ismember( controlZeros, knotsOfMaxMultiplicty );
    
    % The new knots to insert are those control zeros that are not knots of
    % maximum multiplicity
    newKnots = controlZeros(~isZeroOfMaxMultiplicty);
    theSpline = fnrfn( theSpline, newKnots );
    
    % Store the new knots as approximations to zeros
    zeroTracker.AppendZeros( newKnots );
end
% The zeros are just whatever we last got as zeros of the control polygon
theZeros = controlZeros;
end

function theZeros = iZerosOfControlPolygon( p )
% iZerosOfControlPolygon -- find the zeros of the control polygon of a spline
[k, coefs, knots] = fnbrk( p, 'order', 'coefs', 'knots' );

% Find sign changes in the control polygon.
scoefs = sign(coefs);
sc = find( abs(diff(scoefs))>1 );

% Zeros due to sign changes in the control polygon
avknts = aveknt( knots, k );
signChangeZeros = avknts(sc)- coefs(sc)./...
    (coefs(sc+1)-coefs(sc)).*(avknts(sc+1)-avknts(sc));

% Coefficients that are zero, but not the ones from the endpoints
% nor those belonging to proper zero intervals.
coefficientZeros = zeros(1,0);
if any(coefs == 0)
    % Find runs of consecutive zeros
    [temp, lengths] = iFindConsecutiveZeros( coefs );
    % ... except that we don't consider zeros at the endpoints
    if coefs(1) == 0
        temp(1) = [];
        lengths(1) = [];
    end
    if coefs(end) == 0
        temp(end) = [];
        lengths(end) = [];
    end
    
    if ~isempty(temp)
        % generate one zero from each run of consecutive coefs zeros that
        % does not correspond to a proper zero interval of the spline.
        
        % First get zeros from a run of LESS than k
        is_end_of_run_of_less_than_k_zeros = lengths < k;
        index_of_end_of_run_of_less_than_k_zeros = temp(is_end_of_run_of_less_than_k_zeros);
        
        lessThanKZeros = avknts(index_of_end_of_run_of_less_than_k_zeros);
        
        % A run of m>=k consecutive coefs zeros ending at coefs(temp)
        % corresponds to the zero interval knots([temp-m+k,temp+1]), hence is
        % caught earlier only if knots(temp-m+k)<knots(temp+1).
        is_zero_at_a_point = knots(temp-lengths+k)==knots(temp+1);
        index_of_k_zeros_at_a_point = temp(~is_end_of_run_of_less_than_k_zeros & is_zero_at_a_point );
        
        kOrMoreZeros = knots(index_of_k_zeros_at_a_point);
        
        % The zeros due to coefficients that are zero is the union of those
        % due to a run of less than k zeros and those due to a run of k or
        % more.
        coefficientZeros = [lessThanKZeros, kOrMoreZeros];
    end
end

% Combine all the zeros
theZeros = sort( [signChangeZeros, coefficientZeros] );

end

function this = iZeroTracker( order )
% iZeroTracker -- a pseudo-object for tracking zeros
%
%   ZT = iZeroTracker( K ) is a structure with two function handles. K is the
%   order of the spline for which you want to track the zeros of.
%
%   ZT.AppendZeros( Z ) registers the row vector Z as the most recent set of
%   zeros found.
%
%   ZT.IsConverged() returns true if zeros that have been stored are
%   sufficiently close to each other to be considered the same, i.e., that they
%   have converged. Otherwise, false is returned.
%
%   See [MR07] for description of this method for determining convergence.
this = struct( ...
    'AppendZeros', @nAppendZeros, ...
    'IsConverged', @nIsConverged );

% Initialize storage for the zeros
theZeros = zeros( order, 0 );

% We need to know how many times we have appended zeros as we can't determine
% convergence before we have completed "order" iterations. We will reset
% this to zero if the number of zeros that we are tracking changes.
numAppends = 0;

    function nFixSizeOfStoredZeros( numNewZeros )
        % nFixSizeOfStoredZeros -- If the number of zeros being tracked
        % changes then we need to adjust the matrix that stores the history
        % of the tracked zeros and reset the "numAppends" counter.
        numCurrentZeros = size( theZeros, 2 );
        
        % If the number of new zeros is greater than the number of existing
        % zeros, then enlarge the storage
        if numNewZeros > numCurrentZeros
            theZeros(end,numNewZeros) = 0;
            
            % If the number of new zeros is less than the then number of
            % existing zeros, then reduce the storage.
        elseif numNewZeros < numCurrentZeros
            theZeros = theZeros(:,1:numNewZeros);
        end
        
        % If the number of zeros that we are tracking has changed, then
        % reset the "numAppends" counter.
        if numNewZeros ~= numCurrentZeros
            numAppends = 0;
        end

    end

    function nAppendZeros( newZeros )
        nFixSizeOfStoredZeros( length( newZeros ) );
        
        % Move all the old zeros back a row
        theZeros(1:(end-1),:) = theZeros(2:end,:);
        
        % Store the new zeros in the last row
        theZeros(end,:) = newZeros(:).';
        
        % Increment the counter of number of appends.
        numAppends = numAppends + 1;
    end

    function tf = nIsConverged()
        if numAppends > 0 && isempty( theZeros )
            % No zeros. May as well stop.
            tf = true;
        elseif numAppends < order
            % Too few iterations done to be in position to determine
            % convergence.
            tf = false;
        else
            % Convergence is based on the maximum separation between knots.
            tol = 1e-15*max(1,max(theZeros(end,:)));
            dist = zeros( 1, size( theZeros, 2 ) );
            for i = 1:order
                for j = 1:i-1
                    dist = max( dist, abs( theZeros(i,:) - theZeros(j,:) ) );
                end
            end
            tf = max( dist ) < tol;
        end
    end
end
