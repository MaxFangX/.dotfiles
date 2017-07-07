###########################
# System
###########################

# Install brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Install brew cask
brew tap caskroom/cask

# Java
brew cask install java

# Install gpg
brew install gpg

# Install rvm and user executable ruby
# http://www.moncefbelyamani.com/how-to-install-xcode-homebrew-git-rvm-ruby-on-mac/
curl -L https://get.rvm.io | bash -s stable --auto-dotfiles --autolibs=enable --ruby
rvm reinstall 2.4.0 --disable-binary

# Install Cmake so that installing submodules works
brew install cmake

# Install Node
brew install node

# Install Python
brew install python

# Install pip and virtualenv
sudo easy_install pip
pip install virtualenv

# Install PostGreSQL
brew install postgresql

###########################
# VIM
###########################

# Update submodules
git submodule update --init --recursive

# YouCompleteMe
# http://www.nyayapati.com/srao/2014/12/installing-homebrew-macvim-with-youcompleteme-on-yosemite/
pushd ~/.vim/bundle/YouCompleteMe
./install.py --clang-completer
popd

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

# Install vim powerline fonts
# Instructions here: https://github.com/powerline/fonts
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd ..
rm -rf fonts

# Install Vundle plugins
vim +PluginInstall +qall

###########################
# Command line tools
###########################

# ZSH
# Instructions here: http://sourabhbajaj.com/mac-setup/iTerm/zsh.html
brew install zsh zsh-completions
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
chsh -s /usr/local/bin/zsh
chsh -s /bin/zsh

# Oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Install thefuck
brew install thefuck

# Install the silver searcher
brew install the_silver_searcher

# Install tldr
brew install tldr

# Tree
brew install tree

###########################
# Misc
###########################

# Disable Chrome's two finger drag
# https://apple.stackexchange.com/questions/21236/how-do-i-disable-chromes-two-finger-back-forward-navigation
defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool FALSE
