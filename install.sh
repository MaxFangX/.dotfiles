cp ~/.vimrc ~
cp ~/.bashrc ~
git submodule update --init --recursive
cd ~/.vim/bundle/YouCompleteMe
./install.py --clang-completer
