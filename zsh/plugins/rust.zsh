# Rust/Cargo completions
#
# Adapted from oh-my-zsh plugins/rust (MIT)
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/rust

(( $+commands[rustup] && $+commands[cargo] )) || return

local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
[[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

# Set up cargo completion
if [[ ! -f "$cache_dir/_cargo" ]]; then
  autoload -Uz _cargo
  typeset -g -A _comps
  _comps[cargo]=_cargo
fi

# Set up rustup completion
if [[ ! -f "$cache_dir/_rustup" ]]; then
  autoload -Uz _rustup
  typeset -g -A _comps
  _comps[rustup]=_rustup
fi

# Generate completion files in the background
rustup completions zsh >| "$cache_dir/_rustup" &|
cat >| "$cache_dir/_cargo" <<'EOF'
#compdef cargo
source "$(rustup run ${${(z)$(rustup default)}[1]} rustc --print sysroot)"/share/zsh/site-functions/_cargo
EOF
