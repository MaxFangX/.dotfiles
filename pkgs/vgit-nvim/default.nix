# Update with `nix-shell pkgs/update.nix --argstr package vgit-nvim`
#
# @maxfangx's fork of vgit.nvim, whose indexed reviews the nvim keymaps rely
# on. hms links the build to ~/.local/share/nvim/vgit.nvim, where
# nvim/lua/plugins/vgit.lua loads it as a local lazy.nvim plugin unless a
# checkout exists at ~/dev/nvim/vgit.nvim (preferred, so edits there apply
# without an hms). Pinned by commit rev since the fork has no releases.
{
  lib,
  fetchFromGitHub,
  vimPlugins,
  vimUtils,
}:
let
  source = lib.importJSON ./source.json;
in
vimUtils.buildVimPlugin {
  pname = "vgit.nvim";
  inherit (source) version;

  src = fetchFromGitHub {
    owner = "maxfangx";
    repo = "vgit.nvim";
    inherit (source) rev hash;
  };

  # lazy.nvim provides these at runtime; declared so nixpkgs' require
  # check (which loads every module) finds them on the rtp.
  dependencies = with vimPlugins; [
    nvim-web-devicons
    plenary-nvim
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Visual Git plugin for Neovim (fork with indexed reviews)";
    homepage = "https://github.com/maxfangx/vgit.nvim";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
