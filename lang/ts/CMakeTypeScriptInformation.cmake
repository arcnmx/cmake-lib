set(CMAKE_EXECUTABLE_SUFFIX_TypeScript .js)
set(CMAKE_SHARED_LIBRARY_PREFIX_TypeScript "")
set(CMAKE_SHARED_LIBRARY_SUFFIX_TypeScript .xxx)
set(CMAKE_STATIC_LIBRARY_PREFIX_TypeScript "")
set(CMAKE_STATIC_LIBRARY_SUFFIX_TypeScript .tar.gz)

set(CMAKE_TypeScript_COMPILE_OBJECT
	"true"
	#"<CMAKE_TypeScript_COMPILER> -o <OBJECT> -c <SOURCE> <FLAGS>"
)

set(CMAKE_TypeScript_CREATE_STATIC_LIBRARY
	"true"
)

set(CMAKE_TypeScript_CREATE_SHARED_LIBRARY
	"true"
)

set(CMAKE_TypeScript_LINK_EXECUTABLE 
	"true"
	#"<CMAKE_TypeScript_COMPILER> -o <TARGET> -exe <OBJECTS>"
)
set(CMAKE_TypeScript_ARCHIVE_CREATE
	"true"
	#"<CMAKE_TypeScript_COMPILER> -o <TARGET> -exe <OBJECTS>"
)
set(CMAKE_TypeScript_ARCHIVE_FINISH
	"true"
)
set(CMAKE_TypeScript_ARCHIVE_APPEND)

set(CMAKE_TypeScript_INFORMATION_LOADED 1)

if (${CMAKE_VERSION} VERSION_GREATER_EQUAL "3.19")
	cmake_language(DEFER ID typescript_finish DIRECTORY "${CMAKE_SOURCE_DIR}" CALL typescript_finish)
endif()
