foreach (_lib_default ${_lib_default_components})
	include("${CMAKE_LIB_ROOT}/comp/${_lib_default}.cmake")
endforeach()
