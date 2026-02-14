# Home Manager Modules

Modules are layered. Each layer imports its parent, so host
configs only need to import the most-specific layer they need.

```
core.nix            Safe for any machine, including
                    security-critical ones. Shell, editor,
                    basic CLI tools.

  dev.nix           General dev tooling (LSP, formatters,
                    direnv). Not for security-critical machines.

    dev-lexe/       Lexe-specific dev environment: Flutter,
                    Android SDK, protobuf, PostgreSQL, etc.
```

## Host configs

```
lexe-dev-hetzner.nix   Linux server  ->  dev-lexe + omnara
max2022.nix            macOS laptop  ->  dev-lexe
```

A future security-critical machine would import only `core.nix`.
