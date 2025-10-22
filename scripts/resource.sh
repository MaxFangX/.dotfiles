# Symlink dotfiles
ln -sfF ~/.dotfiles/zshrc ~/.zshrc
ln -sfF ~/.dotfiles/common ~/.common
ln -sfF ~/.dotfiles/bashrc ~/.bashrc
ln -sfF ~/.dotfiles/gitconfig ~/.gitconfig
ln -sfF ~/.dotfiles/tmux.conf ~/.tmux.conf
# Neovim
mkdir -p ~/.config
ln -sfn ~/.dotfiles/nvim ~/.config/nvim
ln -sfF ~/.dotfiles/nvim/init.lua ~/.ideavimrc # IntelliJ's copy
# Cargo
mkdir -p ~/.cargo
ln -sfF ~/.dotfiles/cargo/config.toml ~/.cargo/config.toml
# Karabiner
mkdir -p ~/.config/karabiner/assets
ln -sfn \
    ~/.dotfiles/karabiner/assets/complex_modifications \
    ~/.config/karabiner/assets/complex_modifications

# Backup Karabiner config
cp ~/.config/karabiner/karabiner.json ~/.dotfiles/karabiner/

source ~/.zshrc
echo "Sourced ~/.zshrc"
