include_guard()

function(regex_escape var input)
	string(REGEX REPLACE "([][+.*()^])" "\\\\\\1" out "${input}")
	set("${var}" "${out}" PARENT_SCOPE)
endfunction()

function(absolute_path var path base)
	if (${CMAKE_VERSION} VERSION_LESS "3.20") 
		if (IS_ABSOLUTE "${path}")
			set(out "${path}")
		else()
			set(out "${base}/${path}")
		endif()
	else()
		cmake_path(ABSOLUTE_PATH path
			OUTPUT_VARIABLE out
			BASE_DIRECTORY "${base}"
		)
	endif()
	set("${var}" "${out}" PARENT_SCOPE)
endfunction()

# dir should be "${CMAKE_SOURCE_DIR}" or "${CMAKE_CURRENT_SOURCE_DIR}"
function(all_subdirectories var)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ARG
		"APPEND" "DIRECTORY" ""
	)

	set(args)
	if (_ARG_DIRECTORY)
		set(args DIRECTORY "${_ARG_DIRECTORY}")
	endif()
	get_directory_property(dirs ${args} SUBDIRECTORIES)

	if (_ARG_APPEND)
		set(out ${${var}})
	else()
		set(out)
	endif()

	foreach (dir ${dirs})
		subdirectories(dirs ${dir})
		list(APPEND out ${dir} ${dirs})
	endforeach()

	set("${var}" "${out}" PARENT_SCOPE)
endfunction()

function(all_targets var)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ARG
		"RECURSIVE;IMPORTED" "" "DIRECTORIES"
	)
	if (_ARG_IMPORTED)
		if (${CMAKE_VERSION} VERSION_LESS "3.21") 
			message(FATAL_ERROR "IMPORTED_TARGETS is only supported by cmake 3.21 and later")
		endif()
		set(propname IMPORTED_TARGETS)
	else()
		set(propname BUILDSYSTEM_TARGETS)
	endif()
	if (NOT _ARG_DIRECTORIES)
		set(_ARG_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")
	endif()
	if (_ARG_RECURSIVE)
		foreach (dir ${_ARG_DIRECTORIES})
			all_subdirectories(_ARG_DIRECTORIES DIRECTORY "${dir}" APPEND)
		endforeach()
	endif()

	set(out)
	foreach (dir ${_ARG_DIRECTORIES})
		get_directory_property(targets DIRECTORY "${dir}" "${propname}")
		if (targets)
			list(APPEND out ${targets})
		endif()
	endforeach()

	set("${var}" "${out}" PARENT_SCOPE)
endfunction()
