function [nbo,rows,ncols,last,blocks] = bkbrk(blokmat)
%BKBRK Part(s) of an almost block-diagonal matrix.
%
%   [NB,ROWS,NCOLS,LAST,BLOCKS] = BKBRK(BLOKMAT)
%
%   returns the details of the almost block diagonal matrix contained
%   in BLOKMAT, with ROWS and LAST NB-vectors, and BLOCKS a matrix
%   of size  SUM(ROWS)-by-NCOLS.
%
%   BKBRK(BLOKMAT)
%
%   returns nothing, but all parts are printed.
%
%   See also SPCOL, SLVBLK.

%   Copyright 1987-2011 The MathWorks, Inc.

if blokmat(1)==41 % data type number for the spline block format is 41
   % Here are the details of this particular sparse format:
   % The matrix is sum(ROWS)-by-sum(LAST).
   % There are NB blocks. The i-th block has ROWS(i) rows and NCOLS columns.
   % The first column of the (i+1)st block is exactly LAST(i) columns to the
   % right of the first column of the i-th block.
   nb = blokmat(2);
   rows = blokmat(2+(1:nb));
   ncols = blokmat(2+nb+1);
   last = blokmat(3+nb+(1:nb));
   blocks = reshape(blokmat(3+2*nb+(1:sum(rows)*ncols)),sum(rows),ncols);

elseif blokmat(1)==40 % data type number for general almost block diagonal
                      % format is 40;
   nb = blokmat(2);
   rows = blokmat(2+(1:nb));
   cols = blokmat(2+nb+(1:nb));
   last = blokmat(2+2*nb+(1:nb));
   row = cumsum([0,rows]);
   ne = sum(rows);ncols = max(cols);
   len = rows.*cols;
   index = cumsum([2+3*nb len]);
   blocks = zeros(ne,ncols);
   for j=1:nb
      block = reshape(blokmat(index(j)+(1:len(j))),rows(j),cols(j));
      blocks(row(j)+(1:row(j+1)),(1:cols(j))) = block;
   end
else
   error(message('SPLINES:BKBRK:unknownarg'))
end

if nargout==0 % print out the blocks
   if blokmat(1)==41 % generate COLS
      temp = cumsum([0 last]); temp = temp(nb+1)-temp;
      cols = min(temp(1:nb),ncols);
   end
   rowsum = cumsum([0 rows]);
   for j=1:nb
       fprintf( '%s\n', getString(message('SPLINES:resources:BlockHasRows', ...
           num2str(j), int2str(rows(j)))) );
       disp(blocks(rowsum(j)+(1:rows(j)),1:cols(j)))
       fprintf( '%s\n\n', getString(message('SPLINES:resources:NextBlockShiftedOverColumns', ...
           num2str(last(j)))) );
   end
else
   nbo = nb;
end
