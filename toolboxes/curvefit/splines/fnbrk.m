function varargout = fnbrk( fn, varargin )
%FNBRK Name or part(s) of form.
%
%   FNBRK(FN,PART) returns the specified PART of the function in FN. 
%   For most choices of PART, this is some piece of information about the
%   function in FN. For some choices of PART, it is the form of some function
%   related to the function in FN.
%   If PART is a string, then only the beginning character(s) of the 
%   relevant string need be specified.
%
%   Regardless of the form of FN, PART may be 
%
%      'dimension'     for the dimension of the function's target
%      'variables'     for the dimension of the function's domain
%      'coefficients'  for the coefficients in the particular form
%      'interval'      for the basic interval of the function
%      'form'          for the form used to describe the function in FN 
%      [A B], with A and B scalars, for getting a description of the 
%                      univariate function in FN in the same form, but
%                      on the interval [A .. B], and with the basic interval
%                      changed to [A .. B]. For an m-variate function, this
%                      specification must be in the form of a cell-array
%                      with m entries of the form [A B].
%      []  returns FN unchanged (of use when FN is an m-variate function). 
%
%   Depending on the form of FN, additional parts may be asked for.
%
%   If FN is in B-form (or BBform, or rBform), then PART may also be
%
%      'knots'         for the knot sequence
%      'coefficients'  for the B-spline coefficients
%      'number'        for the number of coefficients
%      'order'         for the polynomial order of the spline
%      'breaks'        for the corresponding break sequence
%
%   If FN is in ppform (or rpform), then PART may also be
%
%      'breaks'        for the break sequence   
%      'coefficients'  for the local polynomial coefficients
%      'pieces'        for the number of polynomial pieces
%      'order'         for the polynomial order of the spline
%      an integer, j,  for the ppform of the j-th polynomial piece
%
%   If FN is in stform, then PART may also be
%
%      'centers'       for the centers 
%      'coefficients'  for the coefficients
%      'number'        for the number of coefficients
%      'type'          for the type of stform
%
%   If FN contains an m-variate tensor-product spline with m>1 and 
%   PART is not a string, then it must be a cell-array, of length m .
%
%   [OUT1, ..., OUTo] = FNBRK(FN, PART1, ..., PARTi) returns, in OUTj, the part
%   requested by PARTj, j=1:o, provided o<=i. 
%
%   FNBRK(FN) returns nothing, but prints the 'form' along with all the parts
%   if available.
% 
%   Examples:
%
%      coefs = fnbrk( fn, 'coef' );
%
%   returns the coefficients (from its B-form or its ppform) of the spline
%   in fn.
%
%      p1 = fn2fm(spline(0:4,[0 1 0 -1 1]),'B-');
%      p2 = fnrfn(spmak(augknt([0 4],4),[-1 0 1 2]),2);
%      p1plusp2 = spmak( fnbrk(p1,'k'), fnbrk(p1,'c')+fnbrk(p2,'c') );
%
%   provides the (pointwise) sum of the two functions  p1  and  p2 , and this
%   works since they are both splines of the same order, with the same 
%   knot sequence, and the same target dimension.
%
%      x = 1:10; y = -2:2; [xx, yy] = ndgrid(x,y);
%      pp = csapi({x,y},sqrt((xx -4.5).^2+yy.^2));
%      ppp = fnbrk(pp,{4,[-1 1]});
%
%   gives the spline that agrees with the spline in pp on the rectangle 
%   [b4,b5] x [-1,1] , where b4, b5 are the 4th and 5th point in the 
%   break sequence for the first variable.
%
%   See also SPMAK, PPMAK, RSMAK, RPMAK, STMAK, SPBRK, PPBRK, RSBRK, RPBRK, STBRK.

%   Copyright 1987-2012 The MathWorks, Inc.

if nargin>1
   np = max(1,nargout); % FNBRK(FN,PART) may be part of an expression
   if np <= length(varargin)
      varargout = cell(1,np);
   else
      error(message('SPLINES:FNBRK:moreoutthanin'))
   end
end 

if ~isstruct(fn)    % this branch should eventually be abandoned
   switch fn(1)
   %
   % curves:
   %
      case 10, fnform = getString(message('SPLINES:resources:PpformUnivariate'));
      case 11, fnform = getString(message('SPLINES:resources:BformUnivariate'));
      case 12, fnform = getString(message('SPLINES:resources:BBformUnivariate'));
   %
   % surfaces:
   %
      case 20, fnform = getString(message('SPLINES:resources:PpformTensor'));
      case 21, fnform = getString(message('SPLINES:resources:BformTensor'));
      case 22, fnform = getString(message('SPLINES:resources:BBformBivariate'));
      case 24, fnform = getString(message('SPLINES:resources:PolynomialShiftedPowerForm'));
      case 25, fnform = getString(message('SPLINES:resources:ThinplateSpline'));
   %
   % matrices:
   %
      case 40, fnform = getString(message('SPLINES:resources:BlockDiagonalForm'));
      case 41, fnform = getString(message('SPLINES:resources:BlockDiagonalFormSplineVersion'));
   % 42 = 'factorization of spline version of almost block diagonal form'
   %      (not yet implemented)
   
   %
   % multivariate:
   %
      case 94, fnform = ...
                  getString(message('SPLINES:resources:PolynomialNormalizedPowerForm'));
      otherwise
         error(message('SPLINES:FNBRK:unknownform'))
   end
   
   if nargin>1 %  return some parts if possible
      switch fn(1)
      case 10, [varargout{:}] = ppbrk(fn,varargin{:});
      case {11,12}, [varargout{:}] = spbrk(fn,varargin{:});
      otherwise
         error(message('SPLINES:FNBRK:unknownpart', fnform))
      end
   else        % print available information
      if nargout
         error(message('SPLINES:FNBRK:partneeded'))
      else
         fprintf( '%s\n\n', getString(message('SPLINES:resources:DisplayFunctionInput', fnform)) ) 
         switch fn(1)
         case 10, ppbrk(fn);
         case {11,12}, spbrk(fn);
         otherwise
            fprintf( '%s\n', getString(message('SPLINES:resources:NotAvailablePartsOfFunction')) )
         end
      end
   end
   return
end   
 
     % we reach this point only if FN is a structure.

switch fn.form(1:2) 
case 'pp',        ffbrk = @ppbrk;
case 'rp',        ffbrk = @rpbrk;
case 'st',        ffbrk = @stbrk;
case {'B-','BB'}, ffbrk = @spbrk;
case 'rB',        ffbrk = @rsbrk;
otherwise
   error(message('SPLINES:FNBRK:unknownform'))
end

if nargin>1
   [varargout{:}] = ffbrk(fn,varargin{:});
else
   if nargout
      error(message('SPLINES:FNBRK:partneeded'))
   else
      fprintf( '%s\n\n', getString(message('SPLINES:resources:DisplayFormInput', fn.form(1:2))) ) 
      ffbrk(fn)
   end
end
