#!/bin/bash
# builds and runs the localization tests (a few seconds)
set -e
cd "$(dirname "$0")/.."
mkdir -p /tmp/brasa-tests
swiftc -swift-version 5 tests/main.swift Localization.swift -o /tmp/brasa-tests/idiomas 2>&1 | head -20
/tmp/brasa-tests/idiomas | tail -8
