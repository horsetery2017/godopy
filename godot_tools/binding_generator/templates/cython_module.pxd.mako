# Generated by PyGodot binding generator

from godot.bindings._cython_bindings cimport (
% for class_name in class_names:
    % if classes[class_name]['singleton']:
    ${class_name}Class,
    ${class_name},
    % else:
    ${class_name},
    % endif
    % if classes[class_name]['enums']:
    % for enum in classes[class_name]['enums']:
    ${class_name}${enum['name']},
    % endfor
    % endif
% endfor
)
