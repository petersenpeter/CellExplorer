function st = getallfields(opts)
% GETALLFIELDS Return struct of all fields of a fitoptions object.

% Copyright 2001-2004 The MathWorks, Inc.

st = get(opts);
st.Jacobian = get(opts,'Jacobian'); % Hidden field: must get explicitly
