function height=fitScrollingStack(stack,scroller)
%FITSCROLLINGSTACK Derive the scroll extent from fixed/flexible section sizes.
heights=stack.Heights; minimums=stack.MinimumHeights;
height=sum(max(max(heights,0),minimums))+2*stack.Padding+ ...
    max(0,numel(heights)-1)*stack.Spacing;
scroller.MinimumHeights=max(1,height);
end
