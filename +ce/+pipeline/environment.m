function info = environment
%ENVIRONMENT Execution environment used for conservative stage cache reuse.
info.matlab = version;
info.platform = computer;
info.mexExtension = mexext;
installed = ver;
[~,order] = sort({installed.Name});
info.toolboxes = struct('name',{installed(order).Name},'version',{installed(order).Version});
end
