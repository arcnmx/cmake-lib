include_guard()

function (typescript_finish)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ARG
		"" "" "TARGETS"
	)
	if (NOT _ARG_TARGETS)
		all_targets(targets DIRECTORIES ${CMAKE_SOURCE_DIR} RECURSIVE)
		foreach (target ${targets})
			get_target_language(lang "${target}")
			if ("${lang}" STREQUAL "TypeScript")
				list(APPEND _ARG_TARGETS "${target}")
			endif()
		endforeach()
	endif()
	foreach (target ${_ARG_TARGETS})
		typescript_process_target("${target}")
	endforeach()
endfunction()

function (typescript_process_target)
	get_target_property(sources "${target}" SOURCES)
	message(FATAL_ERROR "TODO something with ${sources}")
endfunction()
