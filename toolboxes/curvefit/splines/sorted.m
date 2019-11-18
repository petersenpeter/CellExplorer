function pointer = sorted(meshsites, sites)
%SORTED Locate sites with respect to meshsites.
%
%   POINTER = SORTED(MESHSITES, SITES) is the  r o w  vector for which
%
%      POINTER(j) = #{ i : MESHSITES(i)  <=  sort(SITES)(j) },  all  j .
%
%   Thus, if both MESHSITES and SITES are nondecreasing, then
%
%      MESHSITES(POINTER(j))  <=  SITES(j)  <  MESHSITES(POINTER(j)+1), all j,
%
%   with POINTER(j) equal to 0 meaning that SITES(j) < MESHSITES(1), and
%   equal to length(MESHSITES) meaning that MESHSITES(end) <= SITES(j).
%
%   Example:
%
%      sorted( 1:4 , [0 1 2.1 2.99 3.5 4 5])
%
%   specifies 1:4 as MESHSITES and [0 1 2.1 2.99 3.5 4 5] as SITES and
%   gives the output  [0 1 2 2 3 4 4], as does
%
%      sorted( 1:4 , [2.99 5 4 0 2.1 1 3.5])
%
%   See also PPUAL, SPVAL.

%   Copyright 1987-2008 The MathWorks, Inc.

[ignored,index] = sort([meshsites(:).' sites(:).']);
pointer = find(index>length(meshsites))-(1:length(sites));
