function obj_out = copyFittypeProperties( obj_out, obj_in )
%COPYFITTYPEPROPERTIES   Copy all the fittype properties from one object to another
%
%   B = COPYFITTYPEPROPERTIES( B, A ) assigns to each property of the FITYYPE B
%   the value of the corresponding property in the FITYYPE B.
%
%   Note that this only applies to FITTYPE properties, If A and/or B are
%   subclasses of FITYYPE, then only the properties that are common to FITTPE
%   are copied.

%   Copyright 2008-2010 The MathWorks, Inc.

obj_out.Adefn = obj_in.Adefn;
obj_out.Aexpr = obj_in.Aexpr;
obj_out.args = obj_in.args;
obj_out.assignCoeff = obj_in.assignCoeff;
obj_out.assignData = obj_in.assignData;
obj_out.assignProb = obj_in.assignProb;
obj_out.fCategory = obj_in.fCategory;
obj_out.coeff = obj_in.coeff;
obj_out.fConstants = obj_in.fConstants;
obj_out.defn = obj_in.defn;
obj_out.depen = obj_in.depen;
obj_out.derexpr = obj_in.derexpr;
obj_out.expr = obj_in.expr;
obj_out.fFeval = obj_in.fFeval;
obj_out.fFitoptions = obj_in.fFitoptions;
obj_out.indep = obj_in.indep;
obj_out.intexpr = obj_in.intexpr;
obj_out.isEmpty = obj_in.isEmpty;
obj_out.linear = obj_in.linear;
obj_out.fNonlinearcoeffs = obj_in.fNonlinearcoeffs;
obj_out.numArgs = obj_in.numArgs;
obj_out.numCoeffs = obj_in.numCoeffs;
obj_out.prob = obj_in.prob;
obj_out.fStartpt = obj_in.fStartpt;
obj_out.fType = obj_in.fType;
obj_out.fTypename = obj_in.fTypename;
obj_out.version = obj_in.version;
    
end
