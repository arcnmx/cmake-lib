include_guard()

function(git_hash var)
	cmake_parse_arguments(
		PARSE_ARGV 1 _GIT
		"SHORT" "" "ARGS"
	)
	if (_GIT_SHORT)
		list(APPEND _GIT_ARGS --short)
	endif()

	find_package(Git)
	if (GIT_FOUND)
		execute_process(
			COMMAND "${GIT_EXECUTABLE}" rev-parse ${_GIT_ARGS} HEAD
			OUTPUT_VARIABLE out
			ERROR_QUIET
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		set("${var}" "${out}" PARENT_SCOPE)
	else()
		set("${var}" "" PARENT_SCOPE)
	endif()
endfunction()

function(git_tag prefix)
	cmake_parse_arguments(
		PARSE_ARGV 1 _GIT
		"CHECK" "PREFIX" "ARGS;SORT"
	)
	if (NOT "${_GIT_PREFIX}" STREQUAL "")
		list(APPEND _GIT_ARGS --list "${_GIT_PREFIX}*")
	endif()
	string(LENGTH "${_GIT_PREFIX}" _GIT_PREFIX_LEN)
	if ("${_GIT_SORT}" STREQUAL "")
		set(_GIT_SORT -version:refname)
	endif()
	list(TRANSFORM _GIT_SORT PREPEND --sort=)

	find_package(Git)
	if (GIT_FOUND)
		execute_process(
			COMMAND "${GIT_EXECUTABLE}" tag --points-at HEAD ${_GIT_SORT} ${_GIT_ARGS} HEAD
			OUTPUT_VARIABLE out
			ERROR_QUIET
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
		string(REPLACE "\n" ";" out "${out}")

		if (NOT "${out}" STREQUAL "")
			list(GET out 0 first)
			if ("${first}" MATCHES "^${_GIT_PREFIX}(.*)-(.*)$")
				set(version "${CMAKE_MATCH_0}")
				set(prerelease "${CMAKE_MATCH_1}")
				if ("${_GIT_PREFIX}${version}" IN_LIST out)
					set(first "${_GIT_PREFIX}${version}")
					unset(prerelease)
				endif()
			else()
				string(SUBSTRING "${first}" "${_GIT_PREFIX_LEN}" -1 version)
				unset(prerelease)
			endif()

			if (_GIT_CHECK AND NOT "${version}" STREQUAL "${PROJECT_VERSION}")
				message(FATAL_ERROR "git tag ${first} does not match expected version: ${PROJECT_VERSION}")
			endif()

			set("${prefix}" "${first}" PARENT_SCOPE)
			set("${prefix}_ALL" "${out}" PARENT_SCOPE)
			set("${prefix}_VERSION" "${version}" PARENT_SCOPE)
			if (DEFINED prerelease)
				set("${prefix}_PRERELEASE" "${prerelease}" PARENT_SCOPE)
			endif()
		else()
		endif()
	else()
		set("${prefix}" "" PARENT_SCOPE)
	endif()
endfunction()
