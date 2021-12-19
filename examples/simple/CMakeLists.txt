cmake_minimum_required(VERSION 3.12)
project(cmake-lib-example
	VERSION 0.0.1
	LANGUAGES
)
option(GLOBAL "test from implicit global scope")

if (NOT GLOBAL)
	set(Lib_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../..")
endif()
find_package(Lib REQUIRED COMPONENTS util)

absolute_path(out CMakeLists.txt "${CMAKE_CURRENT_SOURCE_DIR}")
install(FILES "${out}" TYPE DATA)
