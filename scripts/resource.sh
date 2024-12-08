# Symlink dotfiles
ln -sfF ~/.dotfiles/zshrc ~/.zshrc
ln -sfF ~/.dotfiles/common ~/.common
ln -sfF ~/.dotfiles/bashrc ~/.bashrc
ln -sfF ~/.dotfiles/gitconfig ~/.gitconfig
# Neovim
mkdir -p ~/.config/nvim
ln -sfF ~/.dotfiles/nvim ~/.config # Works differently when symlinking folders
ln -sfF ~/.dotfiles/nvim/init.vim ~/.ideavimrc # IntelliJ's copy
# Karabiner
mkdir -p ~/.config/karabiner/assets/complex_modifications
ln -sfF \
    ~/.dotfiles/karabiner/assets/complex_modifications \
    ~/.config/karabiner/assets # Follow the nvim folder example

# Backup Karabiner config
cp ~/.config/karabiner/karabiner.json ~/.dotfiles/karabiner/

source ~/.zshrc
echo "Sourced ~/.zshrc"
