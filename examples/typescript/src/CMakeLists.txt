add_executable(example index.ts)
target_link_libraries(example PUBLIC example-lib)
set_target_properties(example PROPERTIES
	NODE_PACKAGE_JSON_PATH package.json
	TYPESCRIPT_TSCONFIG_PATH tsconfig.json
)
