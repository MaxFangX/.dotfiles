# Home Manager Modules

Modules are layered. Each layer imports its parent, so host
configs only need to import the most-specific layer they need.

```
core.nix                Base layer. Shell, editor, CLI tools.
│                       Safe for security-critical machines.
│
└── dev.nix             General dev tooling (LSP, formatters,
    │                   direnv). Not for secure machines.
    │
    └── dev-lexe.nix    Lexe-specific dev environment.
        │
        dev-lexe/       Submodules:
        ├── android.nix   Android SDK + emulator
        └── postgres.nix  PostgreSQL (launchd/systemd)
```

## Host configs

```
max-nitropad-2024   Linux (secure) ->  core only
lexe-dev-hetzner/   Linux server   ->  dev-lexe + omnara
max2022.nix         macOS laptop   ->  dev-lexe
```
