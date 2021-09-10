# Copy over the dotfiles
cp ~/.bashrc ~/.dotfiles/bashrc
cp ~/.bash_profile ~/.dotfiles/bash_profile
cp ~/.zshrc ~/.dotfiles/zshrc
cp ~/.gitconfig ~/.dotfiles/gitconfig

# Neovim
cp ~/.config/nvim/init.vim ~/.dotfiles/nvim
rm -rf ~/.dotfiles/nvim/after
cp -R ~/.config/nvim/after ~/.dotfiles/nvim
