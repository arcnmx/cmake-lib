include_guard()
include(./node.cmake)

set(ESBUILD_TARGET "esnext" CACHE STRING "esbuild target")

list(APPEND ESBUILD_FLAGS
	"--target=${ESBUILD_TARGET}"
	$<$<CONFIG:Release>:--minify>
)

find_program(PROGRAM_ESBUILD esbuild REQUIRED)
find_program(PROGRAM_BASH bash REQUIRED)

function(add_esbuild target_name)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ESBUILD
		"EXPLICIT" # list of flags
		"TSCONFIG" # list of single-value options
		"SOURCES;DEPENDS;NODE_MODULES;TYPES_MODULES;ARGS" # multi-value options
	)

	list(TRANSFORM _ESBUILD_TYPES_MODULES PREPEND @types/)
	list(APPEND NODE_MODULES ${_ESBUILD_TYPES_MODULES})
	list(APPEND NODE_MODULES ${_ESBUILD_NODE_MODULES})
	list(REMOVE_DUPLICATES NODE_MODULES)
	set(NODE_MODULES "${NODE_MODULES}" PARENT_SCOPE)
	list(APPEND _ESBUILD_NODE_MODULES ${_ESBUILD_TYPES_MODULES})
	list(TRANSFORM _ESBUILD_NODE_MODULES PREPEND node_modules/)

	if ("${_ESBUILD_TSCONFIG}" STREQUAL "")
		list(PREPEND _ESBUILD_ARGS "--tsconfig=${_ESBUILD_TSCONFIG}")
	endif()

	set(targetbase "${CMAKE_CURRENT_BINARY_DIR}/${target_name}")

	list(PREPEND _ESBUILD_ARGS
		--bundle --sourcemap=both
		${ESBUILD_FLAGS}
		"--outfile=${targetbase}.js"
	)

	list(PREPEND _ESBUILD_DEPENDS ${_ESBUILD_SOURCES})
	list(APPEND _ESBUILD_DEPENDS "${_ESBUILD_TSCONFIG}" ${_ESBUILD_NODE_MODULES})

	add_custom_command(
		OUTPUT "${target_name}.js" "${target_name}.js.map"
		COMMAND "${PROGRAM_ESBUILD}" "${_ESBUILD_ARGS}" "${_ESBUILD_SOURCES}"
		COMMAND "${PROGRAM_BASH}" "${CMAKE_LIB_ROOT}/scripts/parse_jsmap.sh" "${targetbase}.d" "${targetbase}.js.map"
		DEPENDS ${_ESBUILD_DEPENDS}
		DEPFILE "${target_name}.d"
		MAIN_DEPENDENCY ${_ESBUILD_SOURCES}
		WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
		VERBATIM
	)

	if (NOT "${_ESBUILD_EXPLICIT}")
		list(APPEND _ESBUILD_TARGET_FLAGS ALL)
	endif()
	add_custom_target("${target_name}"
		${_ESBUILD_TARGET_FLAGS}
		DEPENDS "${target_name}.js"
	)
endfunction()
