# macOS-only Homebrew packages for Lexe development.
{ lib, pkgs, ... }:
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
      # provider can't sign them).
      "michaelroosz/ssh/libsk-libfido2"
      "materializeinc/crosstools/x86_64-unknown-linux-gnu"
    ];
  };

  # ssh-agent only loads providers under /usr/local/lib, so the installer
  # copies the dylib there. Brew upgrades don't refresh that copy, and it
  # breaks once its linked deps (e.g. openssl) are removed.
  home.activation.checkLibskLibfido2 =
    lib.hm.dag.entryAfter [ "brewBundle" ] ''
      src=/opt/homebrew/opt/libsk-libfido2/libexec/libsk-libfido2.dylib
      dst=/usr/local/lib/libsk-libfido2.dylib
      if [[ -e $src ]] && ! cmp -s "$src" "$dst"; then
        warnEcho "$dst is missing or stale; run: sudo install-libsk-libfido2"
      elif ! ${pkgs.python3}/bin/python3 \
          -c "import ctypes; ctypes.CDLL('$dst')" 2>/dev/null; then
        warnEcho "$dst fails to load; check its deps: otool -L $dst"
      fi
    '';
}
