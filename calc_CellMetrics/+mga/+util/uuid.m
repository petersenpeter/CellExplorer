function id = uuid
%UUID Generate a uuid using java

% let java do the work
id = string(java.util.UUID.randomUUID.toString);

end % uuid