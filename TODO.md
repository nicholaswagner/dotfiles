# TODO

- `config/zsh/zshenv` sources `${HOME}/Repos/dev.nicholaswagner/terminal-colors/themes/.env-gold-dark` from a sibling repo. On a fresh machine that path won't exist, and `setup.sh` (which now sources `zshenv` and runs with `set -euo pipefail`) will abort there. Decide whether to make this dependency optional (guard with `[ -f ... ] &&`), inline a fallback theme, or pull the `terminal-colors` repo as part of bootstrap.
