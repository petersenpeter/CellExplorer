function array3 = ce_append(array1,array2)
% Mimics Matlab's append function introduced in 2019a
%
% By Peter Petersen
% petersen.peter@gmail.com

array3 = strings(1);
for j = 1:numel(array2)
    for i = 1:numel(array1)
        array3(j,i) = [array1{i},array2{j}];
    end
end
array3 = array3(:);
end
