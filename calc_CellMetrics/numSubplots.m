function [p,n]=numSubplots(n)
% Calculate how many rows and columns of sub-plots are needed to
% neatly display n subplots.
% Rob Campbell - January 2010

while isprime(n) && n>4
    n=n+1;
end
p=factor(n);
if length(p)==1
    p=[1,p];
    return
end
while length(p)>2
    if length(p)>=4
        p(1)=p(1)*p(end-1);
        p(2)=p(2)*p(end);
        p(end-1:end)=[];
    else
        p(1)=p(1)*p(2);
        p(2)=[];
    end
    p=sort(p);
end

%Reformat if the column/row ratio is too large: we want a roughly
%square design
while p(2)/p(1)>2.5
    N=n+1;
    [p,n]=numSubplots(N); %Recursive!
end
end