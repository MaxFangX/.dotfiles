# fzf integration
#
# Adapted from oh-my-zsh plugins/fzf (MIT)
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/fzf
#
# Abridged: kept macOS, Debian/Ubuntu, and nix paths

# Modern fzf (>= 0.48.0) has built-in shell integration
_fzf_setup_modern() {
  (( ${+commands[fzf]} )) || return 1

  local fzf_ver=${"$(fzf --version)"#fzf }
  autoload -Uz is-at-least
  is-at-least 0.48.0 ${${(s: :)fzf_ver}[1]} || return 1

  eval "$(fzf --zsh)"
}

# Fallback: find fzf shell scripts in common locations
_fzf_setup_from_dir() {
  local fzf_base fzf_shell

  # Check common locations (homebrew, nix, manual install)
  local fzfdirs=(
    "/opt/homebrew/opt/fzf"
    "/usr/local/opt/fzf"
    "${HOME}/.nix-profile/share/fzf"
    "${HOME}/.fzf"
  )

  for dir in ${fzfdirs}; do
    [[ -d "$dir" ]] && { fzf_base="$dir"; break; }
  done

  [[ -z "$fzf_base" ]] && return 1

  fzf_shell="${fzf_base}/shell"
  [[ -d "$fzf_shell" ]] || fzf_shell="$fzf_base"

  [[ -o interactive ]] && source "${fzf_shell}/completion.zsh" 2>/dev/null
  source "${fzf_shell}/key-bindings.zsh" 2>/dev/null
}

# Fallback: Debian/Ubuntu package locations
_fzf_setup_debian() {
  (( $+commands[apt] || $+commands[apt-get] )) || return 1
  [[ -d /usr/share/doc/fzf/examples ]] || return 1

  local completions="/usr/share/doc/fzf/examples/completion.zsh"
  local key_bindings="/usr/share/doc/fzf/examples/key-bindings.zsh"

  # Older Debian/Ubuntu used a different path
  [[ -f "$completions" ]] || completions="/usr/share/zsh/vendor-completions/_fzf"

  [[ -o interactive ]] && source "$completions" 2>/dev/null
  source "$key_bindings" 2>/dev/null
}

_fzf_setup_modern || _fzf_setup_from_dir || _fzf_setup_debian

unset -f _fzf_setup_modern _fzf_setup_from_dir _fzf_setup_debian

# Set default command if not already set
if [[ -z "$FZF_DEFAULT_COMMAND" ]]; then
  if (( $+commands[fd] )); then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  elif (( $+commands[rg] )); then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
  elif (( $+commands[ag] )); then
    export FZF_DEFAULT_COMMAND='ag -l --hidden -g "" --ignore .git'
  fi
fi
