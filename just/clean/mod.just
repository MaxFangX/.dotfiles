# Free disk space by deleting data that is regenerated on demand. Each recipe
# has its own age threshold (see the script header), chosen so that `just
# clean` with no args is always safe; `days` overrides it (0 = hard clean).

set shell := ["bash", "-euo", "pipefail", "-c"]

# Run every section below; `days` overrides all defaults (0 = hard clean)
all days="": (nix days) (build days) caches (rust days) (ios days)

# GC Nix: expire generations older than `days` (default 30)
nix days="":
    @{{ source_directory() }}/clean.sh nix {{ days }}

# Delete Cargo/npm/Flutter build output untouched for `days` (default 0)
build days="":
    @{{ source_directory() }}/clean.sh build {{ days }}

# Delete package-manager and app caches
caches:
    @{{ source_directory() }}/clean.sh caches

# Uninstall non-default Rust toolchains unused for `days` (default 7)
rust days="":
    @{{ source_directory() }}/clean.sh rust {{ days }}

# Delete old iOS sim runtimes, DerivedData, DeviceSupport > `days` (default 30)
ios days="":
    @{{ source_directory() }}/clean.sh ios {{ days }}
