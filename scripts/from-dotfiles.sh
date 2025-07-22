# Copy over the dotfiles
cp ~/.dotfiles/bashrc ~/.bashrc
cp ~/.dotfiles/common ~/.common
cp ~/.dotfiles/zshrc ~/.zshrc
cp ~/.dotfiles/gitconfig ~/.gitconfig

# Neovim
mkdir -p ~/.config/nvim
cp ~/.dotfiles/nvim/init.lua ~/.config/nvim
cp ~/.dotfiles/nvim/coc-settings.json ~/.config/nvim
rm -rf ~/.config/nvim/after
cp -R ~/.dotfiles/nvim/after ~/.config/nvim
cp ~/.dotfiles/nvim/init.vim ~/.ideavimrc # Also copy for IntelliJ

# Cargo
mkdir -p ~/.cargo
cp ~/.dotfiles/cargo/config.toml ~/.cargo/config.toml
