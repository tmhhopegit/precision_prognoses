function tf = has_field(P, name)
%HAS_FIELD True if a struct field or object property exists.
tf = (isstruct(P) && isfield(P, name)) || (isobject(P) && isprop(P, name));
end
