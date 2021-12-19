# Find the compiler
find_program(CMAKE_TypeScript_COMPILER
	NAMES tsc
	DOC "The TypeScript Compiler" 
)
mark_as_advanced(CMAKE_TypeScript_COMPILER)

set(CMAKE_TypeScript_SOURCE_FILE_EXTENSIONS js;ts;d.ts)
set(CMAKE_TypeScript_IGNORE_EXTENSIONS d.ts)
set(CMAKE_TypeScript_OUTPUT_EXTENSION .o)
set(CMAKE_TypeScript_COMPILER_ENV_VAR "")

configure_file(
	"${CMAKE_CURRENT_LIST_DIR}/CMakeTypeScriptCompiler.cmake.in"
	"${CMAKE_PLATFORM_INFO_DIR}/CMakeTypeScriptCompiler.cmake"
)
