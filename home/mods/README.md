# Home Manager Modules

Modules are layered. Each layer imports its parent, so host
configs only need to import the most-specific layer they need.

```
core.nix                Base layer. Shell, editor, CLI tools.
│                       Safe for security-critical machines.
│
└── dev.nix             General dev tooling (LSP, formatters,
    │                   direnv). Not for secure machines.
    │                   Pulls in paseo.nix (Paseo CLI; the
    │                   always-on daemon stays opt-in).
    │
    └── dev-lexe.nix    Lexe-specific dev environment.
        │
        dev-lexe/       Submodules:
        ├── android.nix   Android SDK + emulator
        ├── ios.nix       iOS/macOS tooling (Darwin only)
        └── postgres.nix  PostgreSQL (launchd/systemd)

homebrew.nix            Declarative Homebrew cask management.
                        Darwin only. Merged via homebrew.casks.
```

## Host configs

```
max-nitropad-2024   Linux (secure) ->  core only
lexe-dev.nix        Linux SGX VM   ->  dev
lexe-dev-hetzner/   Linux server   ->  dev-lexe + omnara
max2022.nix         macOS laptop   ->  dev-lexe
```

`lexe-dev` stops at `dev.nix` rather than `dev-lexe.nix`: its
NixOS config (lexe repo, `nix/nixosConfigs/lexe-dev.nix`) already
runs a system-wide postgres, which `dev-lexe/postgres.nix` would
collide with on port 5432.
