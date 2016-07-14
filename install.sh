git submodule update --init --recursive

# YouCompleteMe
pushd ~/.vim/bundle/YouCompleteMe
./install.py --clang-completer
popd

# ZSH
# Instructions here: http://sourabhbajaj.com/mac-setup/iTerm/zsh.html
# brew install zsh zsh-completions
# curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
# chsh -s /usr/local/bin/zsh

### Typecript

# Tsuquyomi https://github.com/Quramy/tsuquyomi
# git clone https://github.com/Shougo/vimproc.vim.git ~/.vim/bundle/vimproc.vim
pushd ~/.vim/bundle/vimproc.vim
make
popd
git clone https://github.com/Quramy/tsuquyomi.git ~/.vim/bundle/tsuquyomi

# Tern for vim https://github.com/ternjs/tern_for_vim
# requires node
pushd ~/.vim/bundle/tern_for_vim
npm install
popd
