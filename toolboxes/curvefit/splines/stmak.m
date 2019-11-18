function st = stmak(centers,coefs,type,interv)
%STMAK Put together a function in stform.
%
%   ST = STMAK(CENTERS, COEFS) stores into ST the stform of
%   the function 
%
%         x |--> sum_j COEFS(:,j)*psi(x - CENTERS(:,j))
%   with 
%          psi(x) := |x|^2 log(|x|^2) 
%
%   and  |x|  the Euclidean length of the vector  x .
%   CENTERS and COEFS must be matrices with the same number of columns.
%
%   ST = STMAK(CENTERS, COEFS, TYPE) stores into ST the stform of
%   the function
%
%         x |--> sum_j COEFS(:,j)*psi_j(x)
%
%   with the psi_j as indicated by the string TYPE, which can be one
%   of the following: 'tp00', 'tp10', 'tp01', with 'tp' the default.
%   In the following description of these various types, c_j is CENTERS(:,j)
%   and  n  is the number of terms, i.e., equal to size(COEFS,2).
%
%   'tp00': bivariate thin-plate spline
%   psi_j(x) := phi(|x - c_j|^2), j=1:n-3, with phi(t) := t log(t);
%   psi_{n-2}(x) := x(1); psi_{n-1}(x) := x(2); psi_n(x) := 1.
%
%   'tp10': partial derivative of thin-plate spline wrto first argument
%   psi_j(x) := phi(|x - c_j|^2) , j=1:n-1, with  
%   phi(t) := (D_1 t)(log(t)+1)  and  D_1 t the derivative of  
%   t := t(x) := |x - c|^2  wrto x(1); also, psi_n(x) := 1.
%
%   'tp01': partial derivative of thin-plate spline wrto second argument
%   psi_j(x) := phi(|x - c_j|^2) , j=1:n-1, with  
%   phi(t) := (D_2 t)(log(t)+1)  and  D_2 t the derivative of  
%   t := t(x) := |x - c|^2  wrto x(2); also, psi_n(x) := 1.
%
%   'tp': pure bivariate thin-plate spline (the default) 
%   psi_j(x) := phi(|x - c_j|^2), j=1:n, with phi(t) := t log(t).
%   
%   ST = STMAK(CENTERS, COEFS, TYPE, INTERV) sets the basic interval of the
%   stform to the given INTERV which must be of the form {[a1,b1],...}.
%   The default value for INTERV is the smallest axiparallel box that contains
%   all the centers; i.e.,  [ai,bi] is [min(CENTERS(i,:)),max(CENTERS(i,:))],
%   with the following exception: When there is just one center, then the basic
%   interval is the box of sidelength 1 that has that sole center as its
%   lower left corner.
%
%   See also STBRK, STCOL, FNBRK.

%   Copyright 1987-2010 The MathWorks, Inc.

if nargin<3||isempty(type)
   type = 'tp';
else
   if ~strcmp(type(1:2),'tp')
      error(message('SPLINES:STMAK:unknowntype', type))
   end
   for j=length(type):-1:3
      der(j-2) = str2num(type(j));
   end
end

[dce, nce] = size(centers); [dco, nco] = size(coefs);

% check that nco and nce are consistent with the specified type.
if ~exist('der','var')
   exces = 0;
else
   switch dce
   case 1
      exces = 2-der;
   case 2
      switch sum(der)
      case 0, exces = 3;
      case 1, exces = 1;
      case 2, exces = 0;
      end   
   otherwise
      error(message('SPLINES:STMAK:atmostbivar'))
   end
end

if nco~=nce+exces
   error(message('SPLINES:STMAK:centersdontmatchcoefs')) 
end

% st = [25, dce, nce, centers(:)', dco, nco, coefs(:)'];

st.form = ['st-',type];
st.centers = centers;
st.coefs = coefs;
st.ncenters = nce;
st.number = nco;
st.dim = dco;

if nargin<4||isempty(interv)
   % For want of some better idea, define the basic interval as the 
   % bounding box of the centers, i.e., the smallest axiparallel 
   % (hyper-)rectangle that contains all the centers.
   % This can always be altered by STBRK(st,interv).

   if nce==1
      interv = {centers(1,1)+[0 1], centers(2,1)+[0 1]};
   else
      for j=dce:-1:1
         interv{j} = [min(centers(j,:)), max(centers(j,:))];
      end
   end
   st.interv = interv;
else
   try
      st = stbrk(st,interv);
   catch
      error(message('SPLINES:STMAK:wronginterv'))
   end
end
