function binding=bindSection(section,stack,scroller)
%BINDSECTION Keep parent allocation and scroll extent in sync with section rows.
% Retain the returned binding for the lifetime of the section. Its timer and
% listeners are released automatically when the section panel is destroyed.
binding=ce.ui.layout.SectionBinding(section,stack,scroller);
end
