include_guard()

function(generate_sourcedir)
	cmake_parse_arguments(
		PARSE_ARGV 0 _GEN
		"" "DIRECTORY;OUTPUTS_VARIABLE;TARGET" "SOURCES;DEPENDS"
	)
	if (NOT _GEN_DIRECTORY)
		message(FATAL_ERROR "DIRECTORY required by generate_sourcedir")
	endif()

	set(build_dir "${CMAKE_CURRENT_SOURCE_DIR}/${_GEN_DIRECTORY}")

	unset(generated)
	foreach (source_path ${_GEN_SOURCES})
		get_filename_component(source_name "${source_path}" NAME)
		generate_symlink(out "${source_path}" "${build_dir}/${source_name}"
			RELATIVE MKDIR
		)
		list(APPEND generated "${out}")
	endforeach()

	if (_GEN_TARGET)
		add_custom_target("${_GEN_TARGET}"
			SOURCES ${generated}
			DEPENDS ${_GEN_DEPENDS}
		)
	endif()

	if (NOT "${_GEN_OUTPUTS_VARIABLE}" STREQUAL "")
		set("${_GEN_OUTPUTS_VARIABLE}" "${generated}" PARENT_SCOPE)
	endif()
endfunction()

function(generate_symlink var source dest)
	cmake_parse_arguments(
		PARSE_ARGV 3 _GEN
		"MKDIR;RELATIVE;DEST_IS_DIRECTORY" "DEST_BASE_DIRECTORY" "DEPENDS;ARGS"
	)

	if (_GEN_DEST_IS_DIRECTORY)
		get_filename_component(dest_name "${source}" NAME)
		set(dest "${dest}/${dest_name}")
	endif()
	if (NOT _GEN_DEST_BASE_DIRECTORY)
		set(_GEN_DEST_BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
	endif()
	absolute_path(dest_path "${dest}" "${_GEN_DEST_BASE_DIRECTORY}")
	get_filename_component(dest_dir "${dest_path}" DIRECTORY)

	set(target_path "${source}")
	if (_GEN_RELATIVE)
		if (${CMAKE_VERSION} VERSION_LESS "3.20") 
			list(PREPEND _GEN_ARGS -r)
		else()
			cmake_path(RELATIVE_PATH source
				BASE_DIRECTORY "${dest_dir}"
				OUTPUT_VARIABLE target_path
			)
		endif()
	endif()

	set(commands
		COMMAND ln ${_GEN_ARGS} -s -f "${target_path}" "${dest_path}"
	)
	if (_GEN_MKDIR)
		list(PREPEND commands
			COMMAND "${CMAKE_COMMAND}" -E make_directory "${dest_dir}"
		)
	endif()
	add_custom_command(
		OUTPUT "${dest}"
		${commands}
		DEPENDS ${_GEN_DEPENDS} # "${source}"
	)
	set("${var}" "${dest_path}" PARENT_SCOPE)
endfunction()

function(generate_dir var output)
	cmake_parse_arguments(
		PARSE_ARGV 1 _GEN
		"" "BASE_DIRECTORY" ""
	)
	if (NOT _GEN_BASE_DIRECTORY)
		set(_GEN_BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
	endif()

	absolute_path(path "${output}" "${_GEN_BASE_DIRECTORY}")

	get_source_file_property(exists "${path}" GENERATED)
	if (NOT exists)
		add_custom_command(
			OUTPUT "${output}"
			COMMAND "${CMAKE_COMMAND}" -E make_directory "${path}"
		)
	endif()
	set("${var}" "${path}" PARENT_SCOPE)
endfunction()

function(generate_failure var name)
	set(out "mock-failure-${name}")
	add_custom_command(
		OUTPUT "${out}"
		COMMAND "${CMAKE_COMMAND}" -E false
	)
	set("${var}" "${CMAKE_CURRENT_BINARY_DIR}/${out}" PARENT_SCOPE)
endfunction()

function(generate_imported_target target)
	cmake_parse_arguments(
		PARSE_ARGV 1 _GEN
		"" "TYPE;LOCATION" "DEPENDS"
	)
	if (NOT _GEN_TYPE)
		set(_GEN_TYPE UNKNOWN)
	endif()

	if (${CMAKE_VERSION} VERSION_LESS "3.19") 
		add_custom_target("${target}" DEPENDS ${_GEN_DEPENDS})
		#add_library("${target}" "${_GEN_TYPE}" IMPORTED)
	else()
		add_library("${target}" INTERFACE ${_GEN_DEPENDS})
	endif()
	if (_GEN_LOCATION)
		set_target_properties("${target}" PROPERTIES IMPORTED_LOCATION ${_GEN_LOCATION})
	endif()
	if (_GEN_DEPENDS)
		set_target_properties("${target}" PROPERTIES INTERFACE_LINK_DEPENDS "${_GEN_DEPENDS}")
	endif()
endfunction()
