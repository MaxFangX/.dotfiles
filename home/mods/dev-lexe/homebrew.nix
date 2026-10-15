# macOS-only Homebrew packages for Lexe development.
{ ... }:
{
  imports = [
    ../homebrew.nix
  ];

  homebrew = {
    taps = [
      "MaterializeInc/homebrew-crosstools" # SGX cross-compilation
      "michaelroosz/ssh"
    ];
    brews = [
      # SSH FIDO2 provider for YubiKey ed25519-sk keys (macOS's built-in
      # provider can't sign them). After it updates, re-run
      # `sudo install-libsk-libfido2` to refresh the /usr/local/lib copy.
      "michaelroosz/ssh/libsk-libfido2"
      "materializeinc/crosstools/x86_64-unknown-linux-gnu"
    ];
  };
}
