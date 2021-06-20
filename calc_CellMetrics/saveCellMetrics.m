function saveCellMetrics(cell_metrics,file)
    C = strsplit(file,'.');
    format = C{end};
    switch lower(format)
        case 'mat'
            structSize = whos('cell_metrics');
            if numel(structSize)>1
                bytes = structSize(1).bytes;
            else
                bytes = structSize.bytes;
            end
            if bytes/1000000000 > 2
                save(file, 'cell_metrics', '-v7.3','-nocompression')
            else
                save(file, 'cell_metrics');
            end
        case 'json'
            encodedJSON = jsonencode(cell_metrics);
            fid=fopen(file,'w');
            fprintf(fid, encodedJSON);
            fclose(fid);
        case 'nwb'
            
        otherwise
            warning(['Unknown file format: ' file]);
    end
end
