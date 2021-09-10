# Copy over the dotfiles
cp ~/.vim/nvim/init.vim ~/.ideavimrc
cp ~/.vim/.bashrc ~
cp ~/.vim/.bash_profile ~
cp ~/.vim/.zshrc ~
cp ~/.vim/.gitconfig ~

# Neovim
cp ~/.vim/nvim/init.vim ~/.config/nvim
rm -rf ~/.config/nvim/after
cp -R ~/.vim/nvim/after ~/.config/nvim
