# Generated by PyGodot binding generator
<%!
    from godot_tools.binding_generator import (
        python_module_name, is_class_type, is_enum, escape_python,
        CORE_TYPES, NUMPY_TYPES, SPECIAL_ESCAPES,
        remove_nested_type_prefix, clean_signature, make_cython_gdnative_type
    )

    # If COMPILE_PROERTIES is enabled, DYNAMIC_PROPERTIES flag in python_module.py.mako should be disabled and vice versa
    # Enabling this flag will make binding compilation really slow, more than 10 times slower (at least with clang++ on MacOS)
    COMPILE_PROPERTIES = False
    COMPILE_CONSTANTS = False

    enum_values = set()

    def clean_value_name(value_name):
        enum_values.add(value_name)
        return remove_nested_type_prefix(value_name)

    singleton_map = {}

    def get_class_name(name, cls):
        if cls['singleton']:
            singleton_map[name] = name + 'Class'
            return name + 'Class'
        return name

    def get_base_name(name):
        if not name:
            return '_PyWrapped'

        if name in singleton_map:
            return singleton_map[name]

        return name

    def make_arg(arg):
        if arg[3] is not None:
            assert arg[1].startswith('_')
            return arg[1][1:]
        if not is_enum(arg[2]['type']) and is_class_type(arg[2]['type']):
            return '%s._owner' % arg[1]
        if arg[2]['type'] in NUMPY_TYPES:
            return 'cpp.%s_from_PyObject(%s)' % (arg[2]['type'], arg[1])
        if arg[2]['type'] in ('String', 'Variant', 'Array', 'Dictionary'):
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
        elif rt == 'Variant':
            return 'return ret'
        elif rt == 'String':
            return 'return ret.py_str()'
        elif rt == 'Array':
            return 'return ret.to_tuple()'
        elif rt == 'Dictionary':
            return 'return ret.to_python()'
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
        elif rt in CORE_TYPES:
            return 'cdef cpp.{0} ret = '.format(rt)
        elif rt == 'bool':
            return 'cdef bint ret = '
        elif is_enum(rt):
            return 'cdef int ret = '
        else:
            return 'cdef {0} ret = '.format(rt)

    def prop_getter(prop, class_def):
        getter = prop['getter']
        index = prop['index']

        if class_def['name'] == 'Node2D' and getter == 'get_global_transform':
            return 'CanvasItem.get_global_transform'
        elif class_def['name'] == 'Node2D' and getter == 'get_transform':
            return 'CanvasItem.get_transform'
        elif class_def['name'] in ('Slider', 'LineEdit') and getter == 'get_focus_mode':
            return 'Control.get_focus_mode'
        elif class_def['name'] == 'BitmapFont' and getter in ('get_ascent', 'is_distance_field_hint', 'get_height'):
            return 'Font.%s' % getter
        elif class_def['name'] in ('CurveTexture', 'GradientTexture', 'NoiseTexture') and getter == 'get_width':
            return 'Texture.get_width'
        elif class_def['name'] in ('DirectionalLight', 'OmniLight', 'SpotLight') and getter == 'get_param':
            return 'partialmethod(Light.%s, %d)' % (getter, index)
        elif class_def['name'] in ('InputEventAction', 'InputEventJoypadButton', 'InputEventKey', 'InputEventMouseButton', 'InputEventScreenTouch') and getter == 'is_pressed':
            return 'InputEvent.is_pressed'
        elif class_def['name'] == 'InputEventKey' and getter == 'is_echo':
            return 'InputEvent.is_echo'
        elif class_def['name'] == 'NoiseTexture' and getter == 'get_height':
            return 'Texture.get_height'

        if index >= 0:
            return 'partialmethod(%s, %d)' % (escape_python(getter), index)
        return escape_python(getter)

    def prop_setter(prop, class_def):
        setter = prop['setter']
        index = prop['index']

        if class_def['name'] in ('Slider', 'LineEdit') and setter == 'set_focus_mode':
            return 'Control.set_focus_mode'
        elif class_def['name'] in ('DirectionalLight', 'OmniLight', 'SpotLight') and setter == 'set_param':
            return 'partialmethod(Light.%s, %d)' % (setter, index)

        if index >= 0:
            return 'partialmethod(%s, %d)' % (escape_python(setter), index)
        return escape_python(setter)
%>
from godot_headers.gdnative_api cimport godot_object, godot_variant
from ..globals cimport Godot, WARN_PRINT, gdapi, nativescript_1_1_api as ns11api, _python_language_index as PYTHON_IDX

from ..core.defs cimport *
from ..core cimport cpp_types as cpp
from ..core cimport types as py
from ..core._wrapped cimport _PyWrapped
from ..core.tag_db cimport (
    register_global_python_type, get_python_instance,
    register_godot_instance, unregister_godot_instance,
    protect_godot_instance, is_godot_instance_protected
)
from .python cimport __icalls

from cpython.ref cimport Py_DECREF

from ..core._meta cimport __tp_dict, PyType_Modified
from cpython.dict cimport PyDict_Update

from ..core._debug cimport __ob_refcnt
% if COMPILE_PROPERTIES:

from functools import partialmethod
% endif
% for class_name, class_def, includes, forwards, methods in classes:


% if class_def['singleton']:
${class_name} = None

% endif
% if methods:
cdef __${class_name}__method_bindings __${class_name}__mb

% endif
cdef class ${get_class_name(class_name, class_def)}(${get_base_name(class_def['base_class'])}):
    % if class_def['singleton']:
    @staticmethod
    def get_singleton():
        global ${class_name}

        if ${class_name} is None:
            ${class_name} = ${class_name}Class.__new__(${class_name}Class)

        return ${class_name}

    % endif
    % if class_def['singleton']:
    def __cinit__(self):
        % if class_name == 'GlobalConstants':
        self._owner = NULL
        % else:
        self._owner = gdapi.godot_global_get_singleton("${class_name}")
        if self._owner:
            protect_godot_instance(<size_t>self._owner)
        % endif
        self.___CLASS_IS_SCRIPT = False
        self.___CLASS_IS_SINGLETON = True
        self.___CLASS_BINDING_LEVEL = 2
    % else:
    % if not class_def['base_class']:
    def __cinit__(self):
        self._owner = NULL
        self.___CLASS_IS_SCRIPT = False
        self.___CLASS_IS_SINGLETON = False
        self.___CLASS_BINDING_LEVEL = 2
    % if class_def['instanciable']:

    def __dealloc__(self):
        if self._owner and not is_godot_instance_protected(<size_t>self._owner):
            print('DESTROY %s %r' % (hex(<size_t>self._owner), self))
            gdapi.godot_object_destroy(self._owner)
            unregister_godot_instance(self._owner)
            self._owner = NULL
    % endif  ## instanciable
    % endif  ## not base_class
    % endif  ## singleton/else

    % if class_def['instanciable']:
    def __init__(self):
        if self.__class__ is ${class_name}:
            self._owner = gdapi.godot_get_class_constructor("${class_name}")()
            ## delegate = <${class_name}>ns11api.godot_nativescript_get_instance_binding_data(PYTHON_IDX, _owner)
            ## assert (<_Wrapped>delegate)._owner == _owner, <size_t>(<_Wrapped>delegate)._owner
            ## (<_Wrapped>self)._owner = _owner
            register_godot_instance(self._owner, self)
            print('INIT %s %r' % (hex(<size_t>self._owner), self), __ob_refcnt(self))
        else:
            raise RuntimeError("Improperly configured '${class_name}' subclass")

    % else:
    def __init__(self):
        raise RuntimeError('${class_name} is not instanciable')

    % endif
    % for method_name, method, return_type, pxd_signature, signature, args, return_stmt, init_args in methods:
    def ${method_name}(self${', ' if signature else ''}${clean_signature(signature, class_name)}):
    % if method_name == 'free':
        ## [copied from godot-cpp] dirty hack because Object::free is marked virtual but doesn't actually exist...
        if self._owner:
            if is_godot_instance_protected(<size_t>self._owner):
                WARN_PRINT('%r (godot_object *%s) instance is protected' % (self, hex(<size_t>self._owner)))
                return
            print('DESTROY %s %r' % (hex(<size_t>self._owner), self))
            gdapi.godot_object_destroy(self._owner)
            unregister_godot_instance(self._owner)
            self._owner = NULL
    % elif method['has_varargs']:
        % if is_class_type(method['return_type']):
        cdef cpp.Variant __owner = __icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner${', %s' % ', '.join(make_arg(a) for a in args) if args else ''}, cpp.Array(__var_args))
        return get_python_instance(<godot_object *>__owner)
        % else:
        ${return_variable(method)}__icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner${', %s' % ', '.join(make_arg(a) for a in args) if args else ''}, cpp.Array(__var_args))
        ${make_return(method)}
        % endif
        % if method_name == '__call__' and class_name == 'NativeScript':

    cdef godot_object *_new_instance(self):
        return <godot_object *>__icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner, cpp.Array())
        % endif
    % else:
        ## not has_varargs
        ${return_variable(method)}__icalls.${icall_names[class_name + '#' + method_name]}(__${class_name}__mb.mb_${method_name}, self._owner${', %s' % ', '.join(make_arg(a) for a in args) if args else ''})
        ${make_return(method)}
    % endif

    % endfor
    % if COMPILE_PROPERTIES and class_def['name'] not in ('RootMotionView',):  ## FIXME: Incomplete API, no methods defined
    % for prop in class_def['properties']:
    ${escape_python(prop['name'])} = property(${prop_getter(prop, class_def)}, ${prop_setter(prop, class_def)})
    % endfor
    % endif

    @staticmethod
    def __finalize_type(**properties):
        cdef dict __type_dict = __tp_dict(${get_class_name(class_name, class_def)})
        if __type_dict.get('___TYPE_READY', False):
            raise RuntimeError("'${class_name}' is already initialized")

        PyDict_Update(__type_dict, properties)
        __type_dict['___TYPE_READY'] = True
        PyType_Modified(${get_class_name(class_name, class_def)})

    @staticmethod
    def __init_method_bindings():
    % if class_def['singleton']:
        global ${class_name}

        ${class_name} = ${class_name}Class.__new__(${class_name}Class)

    % endif
    % for method_name, method, return_type, pxd_signature, signature, args, return_stmt, init_args in methods:
        __${class_name}__mb.mb_${method_name} = gdapi.godot_method_bind_get_method("${class_def['name']}", "${method['name']}")
    % endfor
    % if not methods and not class_def['singleton']:
        pass
    % endif

    % if COMPILE_CONSTANTS:
    % for enum in class_def['enums']:
        % for value_name, value in enum['values'].items():
${python_module_name(class_name).upper()}_${clean_value_name(value_name)} = ${value}
        % endfor

    % endfor
    % for name, value in ((k, v) for (k, v) in class_def['constants'].items() if k not in enum_values):
${python_module_name(class_name).upper()}_${name} = ${value}
    % endfor
    % endif
% endfor


cdef __init_method_bindings():
% for class_name, class_def, includes, forwards, methods in classes:
    ${get_class_name(class_name, class_def)}.__init_method_bindings()
% endfor


cdef __register_types():
% for class_name, class_def, includes, forwards, methods in classes:
    register_global_python_type(${get_class_name(class_name, class_def)}, ${repr(class_def['name'])})
% endfor
