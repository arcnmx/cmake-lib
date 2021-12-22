#!/usr/bin/env bash
set -eu

cmake -B build -S . --warn-uninitialized
cmake --build build -j
