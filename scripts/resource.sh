# Symlink dotfiles
ln -sfF ~/.dotfiles/zshrc ~/.zshrc
ln -sfF ~/.dotfiles/common ~/.common
ln -sfF ~/.dotfiles/bashrc ~/.bashrc
ln -sfF ~/.dotfiles/gitconfig ~/.gitconfig
# Neovim
mkdir -p ~/.config/nvim
ln -sfF ~/.dotfiles/nvim ~/.config # Works differently when symlinking folders
ln -sfF ~/.dotfiles/nvim/init.vim ~/.ideavimrc # IntelliJ's copy
echo "Recreated symlinks"

source ~/.zshrc
echo "Sourced ~/.zshrc"
