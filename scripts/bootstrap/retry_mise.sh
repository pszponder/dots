#!/bin/sh
# Try mise normally, then offer one force retry after an error.
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
action=$1
shift
case "$action" in
  bootstrap) force=--force-dotfiles ;;
  dotfiles) force=--force ;;
  *) printf 'Unknown setup action: %s\n' "$action" >&2; exit 1 ;;
esac
run() {
  if [ "$action" = bootstrap ]; then
    mise "$@" bootstrap --yes ${retry_force:-}
  else
    mise "$@" dot apply --yes ${retry_force:-}
  fi
}
if run "$@"; then exit 0; fi
printf 'Setup failed. A force retry may overwrite existing dotfiles.\n' >&2
sh "$SCRIPT_DIR/confirm_replacements.sh"
# A second failure propagates; never loop or remove paths manually.
retry_force=$force
run "$@"
