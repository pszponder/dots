# NOTE: zsh sources .zshrc automatically for interactive shells, so this file
# must NOT source it again (doing so ran zinit/compinit/PATH twice on every
# login shell). Keep only login-shell-only logic below.

# Flox (optional default environment activation, only if flox is installed)
# Per Flox's own docs this belongs in .zprofile, not .zshrc: it activates once
# per login shell rather than being re-run for every interactive subshell.
if command -v flox &> /dev/null; then
    eval "$(flox activate)"
fi
