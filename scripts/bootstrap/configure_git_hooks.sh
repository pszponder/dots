#!/bin/sh
# Enable hooks only in this checkout, preserving existing hook setups.
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
if [ ! -e "$repo_dir/.git" ]; then
  printf 'Skipping Git hook setup: checkout has no Git metadata.\n'
  exit 0
fi

cd "$repo_dir"
if [ ! -x .githooks/pre-commit ]; then
  printf 'Cannot enable Git hooks: .githooks/pre-commit is missing or not executable.\n' >&2
  exit 1
fi

hook_path=$(git config --get core.hooksPath || :)
if [ -n "$hook_path" ] && [ "$hook_path" != .githooks ]; then
  printf 'Keeping existing core.hooksPath: %s. Integrate .githooks/pre-commit manually.\n' "$hook_path" >&2
  exit 0
fi
if [ -z "$hook_path" ]; then
  existing_hook=$(git rev-parse --git-path hooks/pre-commit)
  if [ -e "$existing_hook" ] || [ -L "$existing_hook" ]; then
    printf 'Keeping existing pre-commit hook: %s. Integrate .githooks/pre-commit manually.\n' "$existing_hook" >&2
    exit 0
  fi
fi

git config --local core.hooksPath .githooks
printf 'Enabled Betterleaks pre-commit hook for %s.\n' "$repo_dir"
