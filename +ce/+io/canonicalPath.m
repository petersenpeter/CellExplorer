function file=canonicalPath(file)
%CANONICALPATH Resolve relative paths against MATLAB's current directory.
% Java's user.dir does not follow MATLAB cd; make the path absolute first.
file=char(file);
if ~java.io.File(file).isAbsolute
    file=fullfile(pwd,file);
end
file=char(java.io.File(file).getCanonicalPath);
end
