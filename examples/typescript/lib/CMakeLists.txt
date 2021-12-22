add_library(example-lib SHARED index.ts)
set_target_properties(example-lib PROPERTIES
	NODE_PACKAGE_JSON_PATH package.json
	TYPESCRIPT_TSCONFIG_PATH tsconfig.json
)
