#!/usr/bin/env bash
set -euo pipefail

swift --version
swift build --configuration release --jobs 2
swift test --jobs 2

output=$(printf '# Release smoke\n' | .build/release/swiftdansi --no-color)
[[ "$output" == *'Release smoke'* ]] || { echo 'CLI stdin smoke failed' >&2; exit 1; }
