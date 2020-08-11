function concatDatFiles(sources,target)
disp(['Creating concatenated file: ' target])
command = ['copy /b '];

for i = 1:length(sources)-1
    command = [command sources{i},'+'];
end
command = [command sources{end},' ', target];
status = system(command);
disp('Concatenation complete')
