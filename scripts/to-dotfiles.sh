# Copy over the dotfiles
cp ~/.bashrc ~/.dotfiles/bashrc
cp ~/.common ~/.dotfiles/common
cp ~/.zshrc ~/.dotfiles/zshrc
cp ~/.gitconfig ~/.dotfiles/gitconfig

# Neovim
cp ~/.config/nvim/init.vim ~/.dotfiles/nvim
cp ~/.config/nvim/coc-settings.json ~/.dotfiles/nvim
rm -rf ~/.dotfiles/nvim/after
cp -R ~/.config/nvim/after ~/.dotfiles/nvim

# Cargo
cp ~/.cargo/config.toml ~/.dotfiles/cargo/config.toml
