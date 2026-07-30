# lexe-dev — Azure VM for dev work against real SGX hardware
#
# The system layer (postgres, SGX/aesmd, nix-ld, users) is managed by
# NixOS in the lexe repo: nix/nixosConfigs/lexe-dev.nix. Notably that
# already runs a system-wide postgresql_17 with a `lexe-dev` database
# and `maxfangx` as a superuser, so this config deliberately skips
# mods/dev-lexe.nix — its user-level postgres would fight the system
# one over port 5432.
{ ... }:
{
  imports = [
    ./mods/dev.nix
  ];

  home.username = "maxfangx";
  home.homeDirectory = "/home/maxfangx";
  home.stateVersion = "25.05";
}
