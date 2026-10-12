#!/bin/sh
# Shared logging helpers for scripts/.

log_info() {
  printf '%s\n' "ℹ️ [INFO] $*"
}

log_success() {
  printf '%s\n' "✅ [OK] $*"
}

log_warn() {
  printf '%s\n' "⚠️ [WARN] $*"
}

log_error() {
  printf '%s\n' "❌ [ERROR] $*" >&2
}