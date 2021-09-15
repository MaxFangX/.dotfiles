# Copy over the dotfiles
cp ~/.dotfiles/bashrc ~/.bashrc
cp ~/.dotfiles/common ~/.common
cp ~/.dotfiles/zshrc ~/.zshrc
cp ~/.dotfiles/gitconfig ~/.gitconfig

# Neovim
cp ~/.dotfiles/nvim/init.vim ~/.config/nvim
rm -rf ~/.config/nvim/after
cp -R ~/.dotfiles/nvim/after ~/.config/nvim
cp ~/.dotfiles/nvim/init.vim ~/.ideavimrc # Also copy for IntelliJ