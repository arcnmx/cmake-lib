#!/usr/bin/env bash
set -eu

NODE_MODULES="$1"
MODULE_NAME="$2"
MODULE_SRC="$3"

install -d "$NODE_MODULES/$(dirname "$MODULE_NAME")"
ln -sf "$MODULE_SRC" "$NODE_MODULES/$MODULE_NAME"
