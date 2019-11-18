function fn = rscvn(p,u)
%RSCVN Piecewise biarc Hermite interpolation
%
%   RSCVN(P,U) returns a planar piecewise biarc curve (in quadratic rBform)
%   that passes, in order, through the given points P(:,j) and is
%   constructed in the following way.  Between any two distinct points
%   P(:,j) and P(:,j+1), the curve usually consists of two circular arcs
%   (including straight-line segments) which join with tangent continuity,
%   with the first arc starting at P(:,j) and normal there to U(:,j), and
%   the second arc ending at P(:,j+1) and normal there to U(:,j+1), and
%   with the two arcs written as one whenever that is possible. Thus the
%   curve is tangent continuous everywhere except, perhaps, at repeated
%   points, where the curve may have a corner, or when the angle formed
%   by the two segments ending at P(:,j) is unusually small, in which
%   case the curve may have a cusp at that point.
%
%   P must be a real matrix, with two rows, and at least two columns, and any
%   column must be different from at least one of its neighboring columns.
%   U must be a real matrix with two rows, with the same number of columns
%   as P (for two exceptions, see below), and can have no zero column.
%
%   RSCVN(P) chooses the normals in the following way. For j=2:end-1,
%   U(:,j) is the average of the (normalized, right-turning) normals to the
%   vectors P(:,j)-P(:,j-1) and P(:,j+1)-P(:,j). If P(:,1)==P(:,end), then
%   both end normals are chosen as the average of the normals to P(:,2)-P(:,1)
%   and P(:,end)-P(:,end-1), preventing a corner in the resulting closed curve.
%   Otherwise, the end normals are so chosen that there is only one arc over
%   the first and last segment (not-a-knot end condition).
%
%   RSCVN(P,U), with U having exactly two columns, also chooses the interior
%   normals as for the case when U is absent but uses the two columns of U
%   as the end-point normals.
%
%   For example,
%
%      p = [1 0 -1 0 1; 0 1 0 -1 0]; c = rscvn([p(1,:)+1;p(2,:)+1],p);
%
%   generates a circle with the same B-coefficients (up to round-off) as are
%   used in the circle supplied by  rsmak('circle',1,[1;1]) .
%   Here are two letters (note the use of a translation in the plotting of
%   the second letter):
%
%      p = [-1 .8 -1 1 -1 -1 -1; 3 1.75 .5 -1.25 -3 -3  3];
%      i = eye(2); u = i(:,[2 1 2 1 2 1 1]);
%      B = rscvn(p,u); S = rscvn([1 -1 1 -1; 2.5 2.5 -2.5 -2.5]);
%      fnplt(B), hold on, fnplt(fncmb(S,[3;0])), hold off, axis equal
%
%   Here is a square with rounded corners:
%
%      e = .1; i = eye(2);
%      sq = rscvn([1,1,1-e,e-1,-1,-1,e-1,1-e,1; ...
%                  e-1,1-e,1,1,1-e,e-1,-1,-1,e-1], i(:,[1 1 2 2 1 1 2 2 1]));
%
%   See also rsmak, cscvn.

%   Copyright 2005-2013 The MathWorks, Inc.

if size(p,2)<2
    error(message('SPLINES:RSCVN:toofew')),
end

dab = diff(p,[],2);
ns = size(dab,2); % ns is the number of segments
dabnorm = sum(dab.^2);
dabii = find(dabnorm==0);
if ~isempty(dabii) % trivial segments will act as corners; however, they
    % must be isolated
    if dabii(1)==1||dabii(end)==ns||(length(dabii)>1&&any(diff(dabii)==1))
        error(message('SPLINES:RSCVN:triples'))
    else % we now know that each column is different from at least one of its
        % neighbors hence know that there is at least one nontrivial segment.
        dabnorm(dabii) = 1; % to avoid division by zero
    end
end

% abp  is the normal to  dab  that points to the right side of  [a..b] .
abp = [dab(2,:); -dab(1,:)]./repmat(sqrt(dabnorm),2,1);
% made sure the normals are normalized:

if nargin<2,
    u = abp(:,[1 ns]);
end

if ns>1&&size(u,2)==2 % need to generate normals
    
    % at each interior point, use the average of the neighboring
    % segment normals:
    u = [u(:,1),(abp(:,1:end-1)+abp(:,2:end))/2,u(:,2)];
    % this choice needs further modification: in the rare case that a normal is
    % zero, at interior multiple points, and, possibly, at the end points.
    ii = find(u(1,:)==0&u(2,:)==0); % are there zero normals?
    if ~isempty(ii),
        u(:,ii) = dab(:,ii);
    end
    il = dabii+1;
    ir = dabii-1;
    if ns>1&&nargin<2
        if p(:,1)==p(:,end) % make the curve closed
            u(:,[1 end]) = repmat((abp(:,1)+abp(:,end))/2,1,2);
            if u(1,1)==0&&u(2,1)==0,
                u(:,[1 end]) = dab(:,[1 1]);
            end
        else            % use the not-a-knot end condition, i.e., choose the
            % end normals so that there is only one arc for the
            % first and last segment.
            il = [1,il];
            ir = [ir,ns];
        end
    end
    if ~isempty(il)
        u(:,il) = repmat(2*sum(u(:,il+1).*abp(:,il)),2,1).*abp(:,il) - u(:,il+1);
        u(:,ir+1) = repmat(2*sum(u(:,ir).*abp(:,ir)),2,1).*abp(:,ir) - u(:,ir);
    end
    
else
    if size(p,1)~=2||size(u,1)~=2
        error(message('SPLINES:RSCVN:notinplane'))
    end
    if size(p,2)~=size(u,2)
        error(message('SPLINES:RSCVN:inconsistent'))
    end
end

unorm = sqrt(sum(u.^2));
if ~all(unorm)
    error(message('SPLINES:RSCVN:zeronormal'))
end

u = u./repmat(unorm,2,1);
ul = u(:,1:end-1);
ur = u(:,2:end);

% drop all trivial intervals, if any
if ~isempty(dabii)
    p(:,dabii)=[];
    dab(:,dabii)=[];
    abp(:,dabii)=[];
    ul(:,dabii)=[];
    ur(:,dabii)=[];
    ns = ns-length(dabii);
end

cl = sum(abp.*ul);
cr = sum(abp.*ur);
% avoid rounding error effects near extreme situation
cl(abs(cl)<1e-12) = 0;
cr(abs(cr)<1e-12) = 0;
% make sure that both  u  and  v  point to the right side of  [a..b] .
ii = find(cl<0);
if ~isempty(ii),
    ul(:,ii)=-ul(:,ii);
    cl(ii)=-cl(ii);
end
ii = find(cr<0);
if ~isempty(ii),
    ur(:,ii)=-ur(:,ii);
    cr(ii)=-cr(ii);
end

% choose the direction  n  of the line through the centers of the two arcs
% as the reflection across  abp  of the average of  u  and  v
n = abp.*repmat(cl+cr,2,1) - (ul+ur)/2;
% note that n(:,i)==[0;0] iff ul(:,i)==-ur(:,i), but these two vectors
% both point to the right of dab(:,i), hence this can happen only if,
% in addition, ul(:,i) and ur(:,i) are parallel to dab(:,i). Since we only
% consider the line generated by a normal and not the normal's direction,
% it seems unreasonable to treat the situation ul(:,i)==ur(:,i) || dab(:,i)
% any differently. So, for this situation, put a  half-circle over such a
% segment, with the half-circle on the right of the segment [a..b]  iff
% the normal at  a  points away from [a..b].
ii = find(cl==0&cr==0);
if ~isempty(ii),
    n(:,ii) = abp(:,ii);
    ur(:,ii) = -ul(:,ii);
end
% ... and normalize  n :
n = n./repmat(sqrt(sum(n.^2)),2,1);

% now identify the four possible cases:
ii = ones(1,ns);
nu = sum(n.*ul);
ii(abs(nu)>1-1e-12) = 2;
nv = sum(n.*ur);
ij = find(abs(nv)>1-1e-12);
ii(ij) = ii(ij)+2;

% for each segment [a .. b], construct the three interior control points
%  ax, x, xb, and the two nontrivial weights, wl, wr, according to the case
% to which they belong:
intpw = zeros(8,ns);

ij = find(ii==1); % this is case 1, the standard case
if ~isempty(ij)
    % determine q = a + qa(1)*u = b + qa(2)*n,
    % i.e., want  b-a = qa(1)*u + qa(2)*(-n), hence
    % qa = [u -n]\dab;
    % use Cramer's rule to vectorize this calculation:
    qa = [sum(dab(:,ij).*[-n(2,ij);n(1,ij)]); ...
        sum(ul(:,ij).*[dab(2,ij);-dab(1,ij)])]./ ...
        repmat(-sum(ul(:,ij).*[n(2,ij);-n(1,ij)]),2,1);
    dqa = diff(qa);
    % also determine r = b + qb(1)*v = a + qb(2)*n,
    % i.e., want  b-a = qb(1)*(-v) + qb(2)*n
    %qb = [-v n]\dab;
    % use Cramer's rule to vectorize this calculation:
    qb = [sum(dab(:,ij).*[n(2,ij);-n(1,ij)]); ...
        sum(ur(:,ij).*[-dab(2,ij);dab(1,ij)])]./ ...
        repmat(sum(ur(:,ij).*[-n(2,ij);n(1,ij)]),2,1);
    dqb = diff(qb);
    
    %if abs(dqb+dqa)>1e-12, s = dqb/(dqb+dqa);
    %else s = .5; end
    s = dqb+dqa;
    ih = find(abs(s)>1e-12);
    if ~isempty(ih),
        s(ih) = dqb(ih)./s(ih);
    end
    ik = 1:length(ij);
    ik(ih) = [];
    if ~isempty(ik),
        s(ik) = .5;
    end
    
    % With that,
    %ra = s*qa(2); rleft = abs(ra); cleft = a + ra*u;
    %rright = (1-s)*abs(qb(1)); cright = b + (1-s)*qb(1)*v;
    ra = repmat(s.*qa(1,:),2,1);
    rleft = abs(ra(1,:));
    cleft = p(:,ij) + ra.*ul(:,ij);
    rb = repmat((1-s).*qb(1,:),2,1);
    rright = abs(rb(1,:));
    cright = p(:,1+ij) + rb.*ur(:,ij);
    
    % we now need to convert the two arcs into rsform, with coefs
    %   [a  ax  x  xb  b;
    %    1  wl  1  wr  1]
    % compute the common point: X = A + s*(BA + (qa(2)-qa(1))*n)
    %                             = B + (1-s)*(AB + (qb(2)-qb(1))*n)
    %x = cleft - ra*n;
    x = cleft - ra.*n(:,ij);
    % We know that, in case the center is the origin, the middle control point
    % should be the midpoint of the arc, with the corresponding weight the ratio,
    % of the distance from center to midpoint of chord over the radius, as that
    % is also the ratio of the radius over the distance of the center from the
    % `control point', i.e., the point at the intersection of the two tangents.
    % The general case adds to this a translation by the center. This leaves
    % the two end control points still on the arc but moves the middle one in
    % surprising ways.
    %ml = (a+x)/2 - cleft; mr = (b+x)/2 - cright;
    %wl = norm(ml)/rleft; wr = norm(mr)/rright;
    %ax = wl*cleft+ml/wl; xb = wr*cright+mr/wr;
    
    % first check whether there are any biarcs that could be well represented
    % by just one arc:
    is = find(max([rleft; rright]).*abs(1./ra(1,:)-1./rb(1,:))<1.e-8);
    if ~isempty(is) % for these, put in just one arc, but mark it by setting
        % the right weight, now useless, to 0
        ijis = ij(is);
        mm = (p(:,ijis)+p(:,ijis+1))/2 - cleft(:,is);
        wl = sqrt(sum(mm.^2))./rleft(is);
        intpw([1:2,7:8],ijis) = [x(:,is)+repmat(wl-1,2,1).*cleft(:,is); ...
            [wl; zeros(1,length(is))]];
        % now omit these segments from further consideration
        ij(is) = [];
        x(:,is) = [];
        cleft(:,is) = [];
        rleft(is) = [];
        cright(:,is) = [];
        rright(is) = [];
    end
    
    if ~isempty(ij)
        ml = (p(:,ij)+x)/2 - cleft;
        mr = (x+p(:,1+ij))/2 - cright;
        wl = repmat(sqrt(sum(ml.^2))./rleft,2,1);
        wr = repmat(sqrt(sum(mr.^2))./rright,2,1);
        intpw(:,ij) = [wl.*cleft+ml./wl; x; wr.*cright+mr./wr; wl(1,:);wr(1,:)];
    end
end

ij = find(ii==2); % this is case 2:  u || n
if ~isempty(ij)
    %rb = n'*dab/(1-nv);  cright = b + rb*v;
    %x = cright -rb*n;
    %                     mr = (b+x)/2 - cright;
    %wl = 1;              wr = norm(mr)/abs(rb);
    %ax = (a+x)/2;        xb = wr*cright+mr/wr;
    
    rb = repmat(sum(n(:,ij).*dab(:,ij))./(1-nv(ij)),2,1);
    cright = p(:,ij+1) + rb.*ur(:,ij);
    x = cright - rb.*n(:,ij);
    mr = (x+p(:,ij+1))/2 - cright;
    wr = repmat(sqrt(sum(mr.^2))./abs(rb(1,:)),2,1);
    intpw(:,ij) = [(p(:,ij)+x)/2; x; wr.*cright+mr./wr; ...
        ones(1,length(ij)); wr(1,:)];
end

ij = find(ii==3); % this is case 3:       n || v
if ~isempty(ij)
    
    %ra = n'*dab/(nu-1);    cleft = a + ra*u;
    %x = cleft - ra*n;
    %ml = (a+x)/2 - cleft;
    %wl = norm(ml)/abs(ra); wr = 1;
    %ax = wl*cleft+ml/wl;   xb = (x+b)/2;
    
    ra = repmat(sum(n(:,ij).*dab(:,ij))./(nu(ij)-1),2,1);
    cleft = p(:,ij) + ra.*ul(:,ij);
    x = cleft - ra.*n(:,ij);
    ml = (p(:,ij)+x)/2 - cleft;
    wl = repmat(sqrt(sum(ml.^2))./abs(ra(1,:)),2,1);
    intpw(:,ij) = [wl.*cleft + ml./wl; x; (x+p(:,ij+1))/2; ...
        wl(1,:); ones(1,length(ij))];
end

ij = find(ii==4); % this is case 4:  u || n || v
if ~isempty(ij)
    
    % make this straight line a single piece but mark it by
    % setting the right weight, now useless, to 0
    intpw([1:2,7:8],ij) = [(p(:,ij)+p(:,1+ij))/2; ...
        ones(1,length(ij));zeros(1,length(ij))];
end

% fn = rsmak([0 0 0 1 1 2 2 2], [a,ax,x,xb,b; 1 wl 1 wr 1]);

dropii = find(intpw(8,:)==0);
if ~isempty(dropii) % drop the second half of those biarcs since the
    % first already covers all
    drops = [4*dropii,4*dropii-1];
    knots = [0,reshape(repmat(0:2*ns,2,1),1,2*(2*ns+1)),2*ns];
    knots(1+drops) = [];
    coefs = [[reshape([p(:,1:ns);intpw(1:6,:)],2,4*ns),p(:,end)]; ...
        reshape([ones(1,ns);intpw(7,:);ones(1,ns);intpw(8,:)],1,4*ns),1];
    coefs(:,drops) = [];
    fn = rsmak(knots, coefs);
else
    
    fn = rsmak([0,reshape(repmat(0:2*ns,2,1),1,2*(2*ns+1)),2*ns], ...
        [[reshape([p(:,1:ns);intpw(1:6,:)],2,4*ns),p(:,end)]; ...
        reshape([ones(1,ns);intpw(7,:);ones(1,ns);intpw(8,:)],1,4*ns),1]);
end

