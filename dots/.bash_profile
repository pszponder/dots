# ~/.bash_profile
# Bash reads this instead of ~/.profile when it exists.

if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

if [ -f "$HOME/.profile" ]; then
    source "$HOME/.profile"
fi
