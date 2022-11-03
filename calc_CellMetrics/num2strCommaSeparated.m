function s1 = num2strCommaSeparated(n)
    s1 = regexprep(num2str(n),'\s+',', ');