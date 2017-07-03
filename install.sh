# Install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install Cmake so that installing submodules works
brew install cmake

# Install Node
brew install node

git submodule update --init --recursive

# YouCompleteMe
pushd ~/.vim/bundle/YouCompleteMe
./install.py --clang-completer
popd

# ZSH
# Instructions here: http://sourabhbajaj.com/mac-setup/iTerm/zsh.html
brew install zsh zsh-completions
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
chsh -s /usr/local/bin/zsh
chsh -s /bin/zsh

# Oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Tsuquyomi https://github.com/Quramy/tsuquyomi
git clone https://github.com/Shougo/vimproc.vim.git ~/.vim/bundle/vimproc.vim
pushd ~/.vim/bundle/vimproc.vim
make
popd
git clone https://github.com/Quramy/tsuquyomi.git ~/.vim/bundle/tsuquyomi

# Tern for vim https://github.com/ternjs/tern_for_vim
# requires node
pushd ~/.vim/bundle/tern_for_vim
npm install
popd

# Install thefuck
brew install thefuck

# Install the silver searcher
brew install the_silver_searcher

# Install vim powerline fonts
# Instructions here: https://github.com/powerline/fonts
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ..
rm -rf fonts

# Install Vundle plugins
vim +PluginInstall +qall
