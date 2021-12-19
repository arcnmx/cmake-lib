include_guard()

set(FIREFOX_DTS_CMAKE_DIR ${CMAKE_CURRENT_LIST_DIR})

find_program(PROGRAM_NPM npm)
find_program(PROGRAM_YARN yarn)

# add to this to resolve node_modules
set(NODE_MODULES_SEARCH_DIRS "" CACHE STRING "node module search dirs")
function(find_node_module var pkg)
	# TODO: version spec arg, and make it part of target name
	set(IMPORTED 1) # TODO
	set(target "node::${pkg}")

	# check if imported target already exists and return early if so
	if ("${IMPORTED}" AND TARGET "${target}")
		set("${var}" "${target}" PARENT_SCOPE)
		return()
	endif()

	find_path(PACKAGE_JSON NAMES ${pkg}/package.json PATHS ${NODE_MODULES_SEARCH_DIRS} NO_DEFAULT_PATH)
	if (PACKAGE_JSON)
		get_filename_component(package_dir "${PACKAGE_JSON}" DIRECTORY)
		if ("${IMPORTED}")
			add_library("${target}" UNKNOWN IMPORTED)
			set_target_properties("${target}" PROPERTIES
				IMPORTED_LOCATION "${package_dir}"
				OUTPUT_NAME "${pkg}" # TODO: consider reading this from the json
				PACKAGE_JSON_PATH "${PACKAGE_JSON}"
			)
			set("${var}" "${target}" PARENT_SCOPE)
		else()
			message(FATAL_ERROR "TODO")
		endif()
	else()
		find_node_module_npm(_NODE_PKG pkg)
		set("${var}" "${_NODE_PKG}" PARENT_SCOPE)
	endif()
endfunction()

function(find_node_module_npm var pkg)
	# TODO: see https://git.astron.nl/ro/lofar/-/blob/cob-148/CMake/NPMInstall.cmake for prior art here
	message(WARNING "TODO search for ${pkg} on NPM")
	set("${var}" "${pkg}-NOTFOUND" PARENT_SCOPE)
endfunction()

# exports <prefix> and <prefix>_FOUND, as well as <prefix>_<name> for each of NAMES
function(find_node_modules prefix)
	cmake_parse_arguments(
		PARSE_ARGV 1 _NODE
		"IMPORTED;REQUIRED;NODE_MODULES" # list of flags
		"" # list of single-value options
		"NAMES" # multi-value options
	)
	if (NOT "${_NODE_IMPORTED}")
		message(FATAL_ERROR "find_node_modules without IMPORTED is unimplemented")
	else()
		set(interface "node::find::${prefix}")
		set("${prefix}" "${interface}" PARENT_SCOPE)
		set(import_flag IMPORTED)
	endif()

	set(found 1)
	set(pkgs)
	foreach(pkg ${_NODE_NAMES})
		find_node_module(node_pkg "${pkg}" ${import_flag})
		if (NOT node_pkg)
			set(found 0)
			set("${prefix}_${pkg}" "${pkg}-NOTFOUND" PARENT_SCOPE)
			if ("${_NODE_REQUIRED}")
				message(FATAL_ERROR "could not find node module ${pkg}")
			endif()
		else()
			list(APPEND pkgs "${node_pkg}")
			set("${prefix}_${pkg}" "${node_pkg}" PARENT_SCOPE)
		endif()
	endforeach()

	set("${prefix}_FOUND" "${found}" PARENT_SCOPE)
	if ("${_NODE_IMPORTED}")
		add_library("${${prefix}}" INTERFACE)
		target_link_libraries("${${prefix}}" INTERFACE ${pkgs})
	else()
		set("${prefix}" "${pkgs}" PARENT_SCOPE)
	endif()
endfunction()

function(add_node_modules)
	cmake_parse_arguments(
		PARSE_ARGV 0 _NODE
		"EXPLICIT"
		"NAME"
		"MODULES;TARGET_FLAGS"
	)
	if ("${_NODE_NAME}" STREQUAL "")
		set(_NODE_NAME "node_modules")
	endif()
	set(modprefix "node_modules")

	# first flatten out any interface libs...
	set(modules)
	foreach(module ${_NODE_MODULES})
		get_target_property(module_type "${module}" TYPE)
		if("${module_type}" STREQUAL "INTERFACE_LIBRARY")
			get_target_property(module_libs "${module}" LINK_INTERFACE_LIBRARIES)
			list(APPEND modules ${module_libs})
		else()
			list(APPEND modules "${module}")
		endif()
	endforeach()

	set(module_dirs)
	foreach(module ${_NODE_MODULES})
		get_target_property(module_name "${module}" OUTPUT_NAME)
		get_target_property(module_location "${module}" IMPORTED_LOCATION)
		set(outfile "${modprefix}/${module_name}/package.json")
		# TODO: consider whether the dep requires an explicit build step, and perform it?
		add_custom_command(
			OUTPUT "${outfile}"
			COMMAND "${PROGRAM_BASH}" "${CMAKE_LIB_ROOT}/scripts/link_node_module.sh" "${modprefix}" "${module_name}" "${module_location}"
			DEPENDS "${module}"
			MAIN_DEPENDENCY "${module}"
			VERBATIM
		)
		list(APPEND module_dirs "${outfile}")
	endforeach()

	if (NOT "${_NODE_EXPLICIT}")
		list(APPEND _NODE_TARGET_FLAGS "ALL")
	endif()

	add_custom_target("${_NODE_NAME}"
		${_NODE_TARGET_FLAGS}
		DEPENDS ${module_dirs}
	)
endfunction()

# TARGET: build target for use in dependencies
# DEV_TARGET: only as much as necessary for dev
# LOCATION: build output, get(TARGET IMPORTED_LOCATION)
# DEV_LOCATION: for development
# IMPORT_NAME: location under node_modules; the package name optionally qualified with an `@something/` org namespace
function(node_module_get var module property)
	if ("${property}" STREQUAL "TARGET")
		if (TARGET "${module}")
			get_target_property(out "${module}" NODE_TARGET)
			if (NOT out)
				set(out "${module}")
			else()
				node_module_get(out "${out}" TARGET)
			endif()
		else()
			message(FATAL_ERROR "unknown node module \"${module}\"")
		endif()
	elseif ("${property}" STREQUAL "LOCATION")
		node_module_get(target "${module}" TARGET)
		get_target_property(out "${target}" PACKAGE_PATH)
		if (NOT out)
			get_target_property(out "${target}" IMPORTED_LOCATION)
		endif()
	elseif ("${property}" STREQUAL "DEV_LOCATION")
		node_module_get(out "${module}" LOCATION) # TODO
	elseif ("${property}" STREQUAL "DEV_TARGET")
		node_module_get(out "${module}" TARGET) # TODO
	elseif ("${property}" STREQUAL "IMPORT_NAME")
		node_module_get(target "${module}" TARGET)
		get_target_property(out "${target}" NODE_IMPORT_NAME)
	else()
		message(FATAL_ERROR "unrecognized node module property \"${property}\"")
	endif()
	if (NOT out)
		message(FATAL_ERROR "property ${property} on node module ${module} not found")
	endif()
	set("${var}" "${out}" PARENT_SCOPE)
endfunction()

function(generate_node_import target)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ARG
		"SYMLINKS" "OUTPUT_DIRECTORY;TSCONFIG_PATH" "SOURCES;FILES;DEPENDS;MODULES"
	)
	if (NOT _ARG_OUTPUT_DIRECTORY)
		set(_ARG_OUTPUT_DIRECTORY "import")
	endif()
	if (NOT _ARG_TSCONFIG_PATH AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/tsconfig.json")
		set(_ARG_TSCONFIG_PATH "tsconfig.json")
	endif()
	set(symlink_sources ${_ARG_FILES})
	set(_ARG_SYMLINKS 1) # TODO: remove this option
	if (_ARG_SYMLINKS)
		list(APPEND symlink_sources ${_ARG_SOURCES})
	endif()
	absolute_path(import_path "${_ARG_OUTPUT_DIRECTORY}" "${CMAKE_CURRENT_BINARY_DIR}")
	set(import_files)

	set(tsconfig_output)
	if (_ARG_TSCONFIG_PATH)
		absolute_path(tsconfig_path "${_ARG_TSCONFIG_PATH}" "${CMAKE_CURRENT_SOURCE_DIR}")

		set(tsconfig_files)
		foreach (file ${_ARG_SOURCES})
			get_filename_component(file_name "${file}" NAME)
			list(APPEND tsconfig_files "\"${file_name}\"")
		endforeach()
		list(JOIN tsconfig_files ", " tsconfig_files_json)

		set(tsconfig_content "{\
			\"extends\": \"${tsconfig_path}\",\
			\"files\": [${tsconfig_files_json}],\
			\"include\": [],\
			\"compilerOptions\": {\
				\"composite\": true,\
				\"disableReferencedProjectLoad\": true,\
				\"disableSolutionSearching\": true\
			}\
		}")
		# TODO: omit declarationMap for non-debug builds
		#		\"rootDir\": \".\",\
		#		\"typeRoots\": []\
		file(GENERATE OUTPUT "${_ARG_OUTPUT_DIRECTORY}/tsconfig.json"
			CONTENT "${tsconfig_content}"
		)
		set(tsconfig_output "${import_path}/tsconfig.json")
		list(APPEND import_files "${tsconfig_output}")
	endif()

	set(modules)
	foreach (module ${_ARG_MODULES})
		node_module_get(module_path "${module}" LOCATION)
		node_module_get(module_import_name "${module}" IMPORT_NAME)
		generate_symlink(out "${module_path}" "${_ARG_OUTPUT_DIRECTORY}/node_modules/${module_import_name}"
			DEPENDS ${_ARG_DEPENDS}
			MKDIR
		)
		list(APPEND modules "${out}")
	endforeach()

	if (NOT _ARG_SYMLINKS)
		foreach (file ${_ARG_SOURCES})
			get_filename_component(file_name "${file}" NAME)
			file(GENERATE OUTPUT "${_ARG_OUTPUT_DIRECTORY}/${file_name}"
				INPUT "${file}"
			)
			list(APPEND import_files "${import_path}/${file_name}")
		endforeach()
	endif()
	foreach (file ${symlink_sources})
		absolute_path(file_path "${file}" "${CMAKE_CURRENT_SOURCE_DIR}")
		if (EXISTS "${file_path}")
			get_source_file_property(generated "${file}" GENERATED)
		else()
			set(generated TRUE)
		endif()

		generate_symlink(out "${file_path}" "${_ARG_OUTPUT_DIRECTORY}"
			DEPENDS ${_ARG_DEPENDS}
			DEST_IS_DIRECTORY MKDIR
		)
		list(APPEND import_files "${out}")
	endforeach()

	set(depends ${import_files} ${_ARG_FILES} ${_ARG_SOURCES} ${_ARG_FILES})
	set(depends_build ${import_files} ${modules})
	list(APPEND depends ${modules}) # TODO: make two separate targets or something instead!
	generate_imported_target("${target}"
		LOCATION "${import_path}"
		DEPENDS ${depends}
	)
	set_target_properties("${target}" PROPERTIES
		PACKAGE_PATH "${import_path}"
		PACKAGE_JSON_PATH "${import_path}/package.json"
		PACKAGE_TSCONFIG_PATH "${tsconfig_output}"
		PACKAGE_DEPENDS_BUILD "${depends_build}"
		PACKAGE_MODULES "${modules}"
	)
endfunction()

function(generate_node_modules var)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ARG
		"" "NAME" "MODULES;SOURCES"
	)
	set(target "node_modules.${_ARG_NAME}")

	if (_ARG_MODULES)
		set(modules_dir "${CMAKE_CURRENT_SOURCE_DIR}/node_modules")
	endif()

	set(modules)
	foreach (module ${_ARG_MODULES})
		node_module_get(module_target "${module}" DEV_TARGET)
		node_module_get(module_path "${module}" DEV_LOCATION)
		node_module_get(module_import_name "${module}" IMPORT_NAME)
		generate_symlink(module_link "${module_path}" "${modules_dir}/${module_import_name}"
			DEPENDS "${module_target}"
			RELATIVE MKDIR
		)
		LIST(APPEND modules "${module_link}")
	endforeach()

	generate_sourcedir(TARGET "${target}"
		DIRECTORY "node_modules/@self/generated"
		SOURCES ${_ARG_SOURCES}
		DEPENDS ${modules}
	)
	if (TARGET node_modules)
		add_dependencies(node_modules "${target}")
	else()
		add_custom_target(node_modules DEPENDS "${target}")
	endif()
	set(var "${target}" PARENT_SCOPE)
endfunction()

# defines a `node.${name}` module library and ${name} target
# INCLUDES are TDS files
function(add_node_module name)
	cmake_parse_arguments(
		PARSE_ARGV 1 _ARG
		"" "PACKAGE_JSON_PATH;IMPORT_NAME" "MODULES;SOURCES;INCLUDES;RESOURCES"
	)
	set(target "node.${name}")
	if (_ARG_PACKAGE_JSON_PATH)
		set(NODE_MODULE_NAME "${name}")
		configure_file("${_ARG_PACKAGE_JSON_PATH}" package.json @ONLY ESCAPE_QUOTES)
		list(APPEND _ARG_RESOURCES "${CMAKE_CURRENT_BINARY_DIR}/package.json")
	endif()
	if (NOT _ARG_IMPORT_NAME)
		set(_ARG_IMPORT_NAME "${name}")
	endif()

	# imported target (for use with compilers that require an orderly node_modules file tree)
	set(import_root "import")
	set(target_imp "nodeimp.${name}")
	#generate_dir(import "${import_root}") # TODO: reconsider
	set(import "${CMAKE_CURRENT_BINARY_DIR}/${import_root}")
	generate_node_import("${target_imp}"
		SOURCES ${_ARG_SOURCES}
		FILES ${_ARG_INCLUDES} ${_ARG_RESOURCES}
		OUTPUT_DIRECTORY "${import_root}"
		#DEPENDS "${import}"
		MODULES ${_ARG_MODULES}
	)
	set_target_properties("${target_imp}" PROPERTIES
		NODE_IMPORT_NAME "${_ARG_IMPORT_NAME}"
		NODE_DEPENDS "${_ARG_MODULES}"
	)

	set(modules)
	foreach (module ${_ARG_MODULES})
		node_module_get(module_target "${module}" TARGET)
		list(APPEND modules "${module_target}")
	endforeach()

	set(outputs)
	foreach (source ${_ARG_SOURCES})
		absolute_path(source_path "${source}" "${CMAKE_CURRENT_SOURCE_DIR}")
		get_filename_component(outfile "${source}" NAME_WE)
		list(APPEND outputs "${outfile}.js" "${outfile}.d.ts")
	endforeach()
	if (outputs)
		set(sourcemaps "${outputs}")
		set(build_info tsconfig.tsbuildinfo)
		list(TRANSFORM sourcemaps APPEND .map)
		get_target_property(depends "${target_imp}" PACKAGE_DEPENDS_BUILD)
		add_custom_command(
			OUTPUT ${outputs}
			BYPRODUCTS ${build_info} ${sourcemaps}
			COMMAND "${CMAKE_TypeScript_COMPILER}"
				--outDir "${CMAKE_CURRENT_BINARY_DIR}"
				--tsBuildInfoFile "${CMAKE_CURRENT_BINARY_DIR}/${build_info}"
				--rootDir "."
				--moduleResolution Node
				--sourceMap --declarationMap # TODO: only set if debug or relwithdebug
				--preserveSymlinks
				--noEmitOnError
				#--listEmittedFiles
				# TODO: --incremental mode?
			# TODO: wrap and generate depfiles, plus --listEmittedFiles to compare
			# TODO: welp, can't pass --paths via CLI :<
			DEPENDS ${depends} ${_ARG_SOURCES} ${modules}
			WORKING_DIRECTORY "${import}"
			VERBATIM
		)
		list(TRANSFORM outputs PREPEND "${CMAKE_CURRENT_BINARY_DIR}/")
	endif()

	# collect includes (.d.ts)
	set(includes)
	set(includes_sources)
	set(includes_generated)
	foreach (file ${_ARG_INCLUDES})
		get_source_file_property(generated "${file}" GENERATED)
		get_filename_component(file_name "${file}" NAME)
		absolute_path(outpath "${file}" "${CMAKE_CURRENT_BINARY_DIR}")
		if (generated)
			list(APPEND includes_generated "${file}")
		else()
			# TODO: with import/ handled separately, why does this exist?
			#configure_file("${file}" "${file_name}" COPYONLY)
			#set_source_files_properties("${outpath}" PROPERTIES
			#	HEADER_FILE_ONLY TRUE
			#)
			#list(APPEND includes "${outpath}")

			#absolute_path(file_path "${file}" "${CMAKE_CURRENT_SOURCE_DIR}")
			list(APPEND includes_sources "${file}")
		endif()
	endforeach()

	# main output target
	add_library("${target}" INTERFACE)
	target_sources("${target}"
		INTERFACE ${_ARG_INCLUDES} #${_ARG_SOURCES}
		${outputs}
	)
	set_target_properties("${target}" PROPERTIES
		RESOURCE "${_ARG_RESOURCES}"
		PUBLIC_HEADER "${_ARG_INCLUDES}"
		EXPORT_NAME "node::${name}"
		NODE_TARGET "${target_imp}"
	)
	add_custom_target("${name}" ALL
		SOURCES ${_ARG_INCLUDES} ${_ARG_SOURCES} ${_ARG_RESOURCES} ${outputs}
		DEPENDS "${target}"
	)
	set_target_properties("${name}" PROPERTIES
		NODE_TARGET "${target}"
	)

	install(TARGETS "${target}"
		EXPORT "${name}"
		RUNTIME COMPONENT run-time DESTINATION .
		PUBLIC_HEADER COMPONENT development DESTINATION .
		RESOURCE COMPONENT development DESTINATION .
	)
endfunction()
