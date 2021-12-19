cmake_minimum_required(VERSION 3.12)
project(cmake-lib
	VERSION 0.1.0
	DESCRIPTION "cmake utilities"
	HOMEPAGE_URL "https://github.com/arcnmx/cmake-lib"
	LANGUAGES
)
include("${CMAKE_CURRENT_SOURCE_DIR}/src/git.cmake")

option(RELEASE "build a tagged release build")
option(TESTS "enable tests")

set(PROJECT_EXTRA_VERSION)
git_tag(PROJECT_EXTRA_GIT PREFIX v CHECK)
if (PROJECT_EXTRA_GIT AND PROJECT_EXTRA_GIT_PRERELEASE)
	set(PROJECT_EXTRA_VERSION "-${PROJECT_EXTRA_GIT_PRERELEASE}")
endif()
if (NOT RELEASE)
	git_hash(PROJECT_EXTRA_GIT_HASH SHORT)
	if (PROJECT_EXTRA_GIT_HASH)
		string(APPEND PROJECT_EXTRA_VERSION "+git-${PROJECT_EXTRA_GIT_HASH}")
	endif()
endif()

set(OUT_NAME Lib)
add_custom_target(cmake-lib)

include(GNUInstallDirs)
install(DIRECTORY src comp modules scripts lang
	DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/${OUT_NAME}"
)
install(FILES "${OUT_NAME}Config.cmake"
	DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/${OUT_NAME}"
)
