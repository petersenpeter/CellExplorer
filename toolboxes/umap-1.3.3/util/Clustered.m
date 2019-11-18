classdef Clustered <handle
    properties
        xy;
        gt;
        density;
        focusNumClusts;
        focusClusterIds;
    end
    methods
        function this=Clustered(xyData, clusterDetail)
            this.xy=xyData;
            gt.tp=MatLabMap;
            if clusterDetail>=0
               [this.focusNumClusts, this.focusClusterIds, this.density]...
                   =Density.ClusterMedium(xyData);
            end
        end
        
        function bi=getBinIdxs(this, clustIdx)
            if nargin>1
                bi=find(this.density.pointers==clustIdx);
            else
                bi=cell(1, this.focusNumClusts);
                if this.focusNumClusts>0
                    for i=1:this.focusNumClusts
                        bi{i}=find(this.density.pointers==i);
                    end
                end
            end
 
        end
    end
end