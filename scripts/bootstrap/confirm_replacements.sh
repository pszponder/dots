#!/bin/sh
set -eu
[ "${1:-}" != --yes ] || exit 0
[ "${DOTFILES_YES:-}" != 1 ] || exit 0
if [ "${DOTFILES_YES+x}" != x ]; then
  case "${MISE_YES:-}" in 1|true) exit 0 ;; esac
fi
if [ ! -t 0 ]; then
  printf 'Force retry requires a terminal or explicit --yes.\n' >&2
  exit 1
fi
printf 'Retry with force overwrite (no backups)? [y/N] '
IFS= read -r answer || exit 1
case "$answer" in y|Y|yes|YES|Yes) ;; *) printf 'Force retry declined.\n' >&2; exit 1 ;; esac
