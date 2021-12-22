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
		all_subdirectories(dirs DIRECTORY "${dir}")
		list(APPEND out "${dir}" ${dirs})
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

function(get_source_file_language var source)
	get_source_file_property(out "${source}" LANGUAGE)
	if (NOT out)
		get_filename_component(source_ext "${source}" EXT)
		string(SUBSTRING "${source_ext}" 1 -1 source_ext) # remove leading dot
		get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
		foreach (lang ${languages})
			set(extensions "${CMAKE_${lang}_SOURCE_FILE_EXTENSIONS}")
			if ("${source_ext}" IN_LIST extensions)
				if (out)
					message(SEND_ERROR "multiple languages found for ${source}")
				endif()
				set(out "${lang}")
			endif()
		endforeach()
	endif()
	set("${var}" "${out}" PARENT_SCOPE)
endfunction()

function(get_target_languages var target)
	set(out)
	get_target_property(sources "${target}" SOURCES)
	foreach (source ${sources})
		get_source_file_language(lang "${source}")
		if (lang)
			list(APPEND out "${lang}")
		endif()
	endforeach()
	list(REMOVE_DUPLICATES out)

	set("${var}" "${out}" PARENT_SCOPE)
endfunction()

function(get_target_language var target)
	cmake_parse_arguments(
		PARSE_ARGV 2 _ARG
		"" "" "REQUIRED"
	)

	get_target_property(out "${target}" LINKER_LANGUAGE)
	if (NOT out)
		get_target_languages(out "${target}")
		list(LENGTH out len)
		if (len GREATER 1)
			message(FATAL_ERROR "multiple languages found for ${target}: ${out} ${lang}")
		endif()
	endif()

	if (NOT out AND _ARG_REQUIRED)
		message(FATAL_ERROR "could not determine language for ${target}")
	endif()
	set("${var}" "${out}" PARENT_SCOPE)
endfunction()
