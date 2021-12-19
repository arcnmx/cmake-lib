#!/usr/bin/env bash
set -eu

OUTPUT="$1"
shift

jq -r '.sources[]' "$@" > "$OUTPUT"
