# NOTE: zsh sources .zshrc automatically for interactive shells, so this file
# must NOT source it again (doing so ran zinit/compinit/PATH twice on every
# login shell). Keep only login-shell-only logic below.

# Activate the default environment as recommended by Flox.
if command -v flox >/dev/null 2>&1; then
  eval "$(flox activate -D -m run)"
fi
