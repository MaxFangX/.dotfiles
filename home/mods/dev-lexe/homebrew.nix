# macOS-only Homebrew packages for Lexe development.
{ ... }:
{
  imports = [
    ../homebrew.nix
  ];

  homebrew = {
    taps = [
      "MaterializeInc/homebrew-crosstools" # SGX cross-compilation
    ];
    brews = [
      "libfido2" # YubiKey FIDO2 support for SSH
      "materializeinc/crosstools/x86_64-unknown-linux-gnu"
    ];
  };
}
