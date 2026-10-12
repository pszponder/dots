# ~/.bash_profile
#
# Bash only sources this (not ~/.bashrc) for login shells, so pull .bashrc in
# explicitly. Mirrors ~/.config/zsh/.zprofile.

# Source bashrc if it exists
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Flox (optional default environment activation, only if flox is installed)
# Per Flox's own docs this belongs in the login-shell profile, not the
# interactive rc file: it activates once per login shell rather than being
# re-run for every interactive subshell.
if command -v flox &> /dev/null; then
    eval "$(flox activate)"
fi
