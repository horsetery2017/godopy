# Generated by PyGodot binding generator
<%!
    from pygodot.bindings._generator import CORE_TYPES
%>
from godot_headers.gdnative_api cimport godot_method_bind, godot_object
from pygodot.bindings.cpp.core_types cimport bool, real_t, int64_t, ${', '.join(CORE_TYPES)}

cdef extern from "__cython_icalls.hpp" namespace "godot" nogil:
% for ret, args, sig, pxd_signature in icalls:
    ${pxd_signature}

% endfor