include_guard()

function(nix_build_exec var attr)
	cmake_parse_arguments(
		PARSE_ARGV 2 _NIX
		"" "BINARY;CACHE;FILE;OUTPUT" "ARGS"
	)
	if (NOT _NIX_FILE)
		set(_NIX_FILE "${CMAKE_CURRENT_SOURCE_DIR}")
	endif()
	if (_NIX_OUTPUT)
		list(APPEND _NIX_ARGS --out-link "${_NIX_OUTPUT}")
	else()
		list(APPEND _NIX_ARGS --no-out-link)
	endif()

	find_program(PROGRAM_NIX_BUILD nix-build)

	execute_process(
		COMMAND "${PROGRAM_NIX_BUILD}" "${_NIX_FILE}" -A "${attr}" ${_NIX_ARGS}
		OUTPUT_VARIABLE out
		OUTPUT_STRIP_TRAILING_WHITESPACE
		COMMAND_ERROR_IS_FATAL ANY
	)

	set(cache_mode PATH)
	if (NOT "${_NIX_BINARY}" STREQUAL "")
		string(APPEND out "/bin/${_NIX_BINARY}")
		set(cache_mode STRING)
	endif()

	if (NOT "${_NIX_CACHE}" STREQUAL "")
		set("${var}" "${out}" CACHE "${cache_mode}" "${_NIX_CACHE}" FORCE)
	else()
		set("${var}" "${out}" PARENT_SCOPE)
	endif()
endfunction()
