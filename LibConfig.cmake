set(Lib_ROOT "${CMAKE_CURRENT_LIST_DIR}")
set(CMAKE_LIB_ROOT "${Lib_ROOT}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_LIB_ROOT}/modules")

set(_lib_default_components util)

set(_lib_components "${${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS}")

foreach (_lib_comp ${_lib_components})
	set(_lib_path "${CMAKE_LIB_ROOT}/comp/${_lib_comp}.cmake")
	set(_lib_opt "${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED_${_lib_comp}")
	if (${_lib_opt})
		include("${_lib_path}")
	else()
		include("${_lib_path}" OPTIONAL)
	endif()
endforeach()

set("${CMAKE_FIND_PACKAGE_NAME}_FOUND" TRUE)
