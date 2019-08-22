# Generated by PyGodot binding generator
from godot_headers.gdnative_api cimport godot_method_bind, godot_object

from ..core._wrapped cimport _PyWrapped

cdef __register_types()
cdef __init_method_bindings()
% for class_name, class_def, includes, forwards, methods in classes:

  % if methods:
cdef struct __${class_name}__method_bindings:
        % for method_name, method, return_type, pxd_signature, signature, args, return_stmt, init_args in methods:
    godot_method_bind *mb_${method_name}
        % endfor
    % endif

cdef class ${class_name}(${class_def['base_class'] or '_PyWrapped'}):
    % if class_def['instanciable']:

    @staticmethod
    cdef ${class_name} _new()
    % else:
    pass
    % endif
    % if class_name == 'NativeScript':

    cdef godot_object *_new_instance(self)
    % endif
% endfor
