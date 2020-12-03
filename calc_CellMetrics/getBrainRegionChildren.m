function acronym_out = getBrainRegionChildren(acronym_in,relational_tree)
    
    acronym_out = [];
    if ~exist('relational_tree','var')
        load('brainRegions_relational_tree.mat','relational_tree');
    end
    
    if ischar(acronym_in)
        acronyms_to_filter{1} = acronym_in;
    else
        acronyms_to_filter = acronym_in;
    end
    
    for j = 1:numel(acronyms_to_filter)
        if any(strcmpi(relational_tree.acronyms,acronyms_to_filter{j}))
            % IDX of acronym
            idx = find(strcmpi(relational_tree.acronyms,acronyms_to_filter{j}));
            
            % Determining children og brain region
            out2 = searchRecurvesively(relational_tree.relationships,relational_tree.relationships_names{idx});
            
            % Finding all fields below
            if ~isempty(out2)
                temp2 = fieldnamesRecurvesively(out2,[]);
                temp3 = find(contains(relational_tree.relationships_names,temp2));
                acronym_out = [acronym_out,relational_tree.acronyms(temp3)];
            end
        end
    end
    
end

function out = searchRecurvesively(relationships,in)
    out = [];
    temp = fieldnames(relationships);
    if any(strcmpi(temp,in))
        out = relationships.(in);
    else
        for i = 1:numel(temp)
            if ~isempty(relationships.(temp{i}))
                out = searchRecurvesively(relationships.(temp{i}),in);
                if ~isempty(out)
                    return
                end
            end
            
        end
    end
    
end

function out = fieldnamesRecurvesively(struct_in,out)
    temp = fieldnames(struct_in);
    out = [out;temp];
    for i = 1:numel(temp)
        if ~isempty(struct_in.(temp{i}))
            out = fieldnamesRecurvesively(struct_in.(temp{i}),out);
        end
    end
end