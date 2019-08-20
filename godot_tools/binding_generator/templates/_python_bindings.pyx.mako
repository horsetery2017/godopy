# Generated by PyGodot binding generator
<%!
    from godot_tools.binding_generator import (
        python_module_name, is_class_type, is_enum,
        CORE_TYPES, NUMPY_TYPES, SPECIAL_ESCAPES,
        remove_nested_type_prefix, clean_signature, make_cython_gdnative_type
    )

    enum_values = set()

    def clean_value_name(value_name):
        enum_values.add(value_name)
        return remove_nested_type_prefix(value_name)

    def make_arg(arg):
        if arg[3] is not None:
            assert arg[1].startswith('_')
            return arg[1][1:]
        if not is_enum(arg[2]['type']) and is_class_type(arg[2]['type']):
            return '%s._owner' % arg[1]
        if arg[2]['type'] in NUMPY_TYPES:
            return 'cpp.%s_from_PyObject(%s)' % (arg[2]['type'], arg[1])
        if arg[2]['type'] in ('String', 'Variant', 'Array'):
            return 'cpp.%s(%s)' % (arg[2]['type'], arg[1])
        if arg[2]['type'] in CORE_TYPES:
            return '%s._cpp_object' % arg[1]

        return arg[1]

    def make_default_arg_type(arg_type):
        return arg_type.rstrip('*').rstrip().replace('const ', '')

    def make_return(method):
        rt = method['return_type']

        if rt == 'void':
            return ''
        elif rt in ('Variant', 'Array'):
            return 'return ret'
        elif rt == 'String':
            return 'return ret.py_str()'
        # elif rt in NUMPY_TYPES:
        #    return 'return ret.to_numpy()'
        elif rt in CORE_TYPES:
            return 'return py.%s.from_cpp(ret)' % rt
        else:
            return 'return ret'

    def return_variable(method):
        rt = method['return_type']
        if rt == 'void':
            return ''
        elif rt == 'Variant':
            return 'cdef object ret = <object>'
        elif rt == 'Array':
            return 'cdef object ret = <object><cpp.Variant>'
        elif rt in CORE_TYPES:
            return 'cdef cpp.{0} ret = '.format(rt)
        elif rt == 'bool':
            return 'cdef bint ret = '
        elif is_enum(rt):
            return 'cdef int ret = '
        else:
            return 'cdef {0} ret = '.format(rt)
%>
from godot_headers.gdnative_api cimport godot_object, godot_variant
from ..globals cimport Godot, gdapi, nativescript_1_1_api as ns11api, _python_language_index

from ..core.defs cimport *
from ..core cimport cpp_types as cpp
from ..core cimport types as py
from ..core._wrapped cimport _PyWrapped
from ..core.tag_db cimport register_global_python_type, get_instance_from_owner
from .python cimport __icalls

from cpython.ref cimport Py_DECREF
% for class_name, class_def, includes, forwards, methods in classes:


% if class_def['singleton']:
cdef object __${class_name}___singleton = None

% endif
% if methods:
cdef __${class_name}__method_bindings __${class_name}__mb

% endif
cdef class ${class_name}(${class_def['base_class'] or '_PyWrapped'}):
    % if class_def['singleton']:
    @staticmethod
    def get_singleton():
        global __${class_name}___singleton

        if __${class_name}___singleton is None:
            __${class_name}___singleton = ${class_name}.__new__(${class_name})

        return __${class_name}___singleton

    % endif
    def __cinit__(self):
    % if class_def['singleton']:
        self._owner = gdapi.godot_global_get_singleton("${class_name}")
        self.___CLASS_IS_SCRIPT = False
        self.___CLASS_IS_SINGLETON = True
        self.___CLASS_BINDING_LEVEL = 2
    % else:
    % if class_def['base_class']:
        pass
    % else:
        self._owner = NULL
        self.___CLASS_IS_SCRIPT = False
        self.___CLASS_IS_SINGLETON = False
        self.___CLASS_BINDING_LEVEL = 2
    % endif  ## base_class/else
    % endif  ## singleton/else

    % if class_def['instanciable']:
    def __init__(self):
        # Ensure ${class_name}() call will create a correct wrapper object
        cdef ${class_name} delegate = ${class_name}._new()
        self._owner = delegate._owner
        Py_DECREF(delegate)

    @staticmethod
    cdef ${class_name} _new():
        return <${class_name}>ns11api.godot_nativescript_get_instance_binding_data(_python_language_index, gdapi.godot_get_class_constructor("${class_def['name']}")())

    % else:
    def __init__(self):
        raise RuntimeError('${class_name} is not instanciable')

    % endif
    % for method_name, method, return_type, pxd_signature, signature, args, return_stmt, init_args in methods:
    def ${method_name}(self${', ' if signature else ''}${clean_signature(signature, class_name)}):
    % if method_name in ('free', '__del__'):
        ## [copied from godot-cpp] dirty hack because Object::free is marked virtual but doesn't actually exist...
        gdapi.godot_object_destroy(self._owner)
        self._owner = NULL
    % elif method['has_varargs']:
        % if is_class_type(method['return_type']):
        cdef cpp.Variant __owner = __icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner${', %s' % ', '.join(make_arg(a) for a in args) if args else ''}, cpp.Array(__var_args))
        return get_instance_from_owner(<godot_object *>__owner)
        % else:
        ${return_variable(method)}__icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner${', %s' % ', '.join(make_arg(a) for a in args) if args else ''}, cpp.Array(__var_args))
        ${make_return(method)}
        % endif
    % else:
        ## not has_varargs
        ${return_variable(method)}__icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner${', %s' % ', '.join(make_arg(a) for a in args) if args else ''})
        ${make_return(method)}
    % endif

    % endfor

    @staticmethod
    def __init_method_bindings():
    % for method_name, method, return_type, pxd_signature, signature, args, return_stmt, init_args in methods:
        __${class_name}__mb.mb_${method_name} = gdapi.godot_method_bind_get_method("${class_def['name']}", "${method['name']}")
    % endfor
    % if not methods:
        pass
    % endif

    % for enum in class_def['enums']:
        % for value_name, value in enum['values'].items():
${python_module_name(class_name).upper()}_${clean_value_name(value_name)} = ${value}
        % endfor

    % endfor
    % for name, value in ((k, v) for (k, v) in class_def['constants'].items() if k not in enum_values):
${python_module_name(class_name).upper()}_${name} = ${value}
    % endfor
% endfor


cdef __init_method_bindings():
% for class_name, class_def, includes, forwards, methods in classes:
    ${class_name}.__init_method_bindings()
% endfor


cdef __register_types():
% for class_name, class_def, includes, forwards, methods in classes:
    register_global_python_type(${class_name}, ${repr(class_def['name'])})
% endfor
