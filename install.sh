cp ~/.vimrc ~
cp ~/.bashrc ~
git submodule update --init --recursive
cd ~/.vim/bundle/YouCompleteMe
./install.py --clang-completer
cd ~/.vim

#Z ZSH
# Instructions here: http://sourabhbajaj.com/mac-setup/iTerm/zsh.html
brew install zsh zsh-completions
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
chsh -s /usr/local/bin/zsh
