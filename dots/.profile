# ~/.profile

# Activate the default environment as recommended by Flox.
if command -v flox >/dev/null 2>&1; then
  eval "$(flox activate -D -m run)"
fi
