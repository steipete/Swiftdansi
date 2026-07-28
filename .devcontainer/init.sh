#!/bin/bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
git_common_dir=$(git rev-parse --git-common-dir)
case "$git_common_dir" in
  /*) ;;
  *) git_common_dir="$PWD/$git_common_dir" ;;
esac

env_file="${script_dir}/.env"
printf 'GIT_REPO=%s\n' "$(realpath "$git_common_dir")" >"${env_file}"
printf 'WORKSPACE_DIR=%s\n' "$(realpath "$PWD")" >>"${env_file}"
