# Copy over the dotfiles
cp ~/.ideavimrc ~/.vim/nvim/init.vim
cp ~/.bashrc ~/.vim/.bashrc
cp ~/.bash_profile ~/.vim/.bash_profile
cp ~/.zshrc ~/.vim/.zshrc
cp ~/.gitconfig ~/.vim/.gitconfig

# Neovim
cp ~/.config/nvim/init.vim ~/.vim/nvim
rm -rf ~/.vim/after
cp -R ~/.config/nvim/after ~/.vim/nvim
