cmake_minimum_required(VERSION 3.12)
project(cmake-lib-example-typescript
	VERSION 0.1.0
	DESCRIPTION "cmake-lib typescript example"
	HOMEPAGE_URL "https://github.com/arcnmx/cmake-lib"
	LANGUAGES
)
set(PROJECT_EXTRA_AUTHOR arc)
set(PROJECT_EXTRA_REPO github:arcnmx/cmake-lib)
set(PROJECT_EXTRA_LICENSE MIT)

option(GLOBAL "test from implicit global scope")

if (NOT GLOBAL)
	set(Lib_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
endif()
find_package(Lib REQUIRED COMPONENTS lang ts)

enable_language(TypeScript)

add_subdirectory(lib)
add_subdirectory(src)

if (${CMAKE_VERSION} VERSION_LESS "3.19")
	# NOTE: if cmake target is 3.19 or newer, this can be omitted
	typescript_finish()
endif()
