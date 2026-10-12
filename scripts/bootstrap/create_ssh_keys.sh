#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source "$SCRIPT_DIR/../utils/utils_logging.sh"
SSHKEYGEN="$SCRIPT_DIR/../../dots/.local/bin/sshkeygen"

# Keep private keys on each machine, never in the repository.
DEFAULT_KEYS=(
  "ed25519|$HOME/.ssh|default|default key"
  "ed25519|$HOME/.ssh/github/pszponder|personal|github pszponder"
)

for entry in "${DEFAULT_KEYS[@]}"; do
  IFS='|' read -r key_type key_dir key_name key_comment <<< "$entry"
  key_path="$key_dir/$key_name"
  if [[ -e "$key_path" || -L "$key_path" ]]; then
    [[ -f "$key_path" && ! -L "$key_path" ]] || {
      log_error "Refusing non-regular private key: $key_path"
      exit 1
    }
    log_info "Keeping existing key: $key_path"
    continue
  fi
  if [[ -e "$key_path.pub" || -L "$key_path.pub" ]]; then
    log_error "Public key exists without its private key: $key_path.pub; resolve manually"
    exit 1
  fi
  if [[ ! -t 0 ]]; then
    log_error "Missing key $key_path; rerun bootstrap in a terminal for the passphrase prompt"
    exit 1
  fi
  bash "$SSHKEYGEN" -t "$key_type" -d "$key_dir" -n "$key_name" -c "$key_comment" -A -q
done
