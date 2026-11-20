# Free disk space by deleting data that is regenerated on demand. Each recipe
# has its own age threshold (see the script header), chosen so that `just
# clean` with no args is always safe; `days` overrides it (0 = hard clean).

set shell := ["bash", "-euo", "pipefail", "-c"]

# Run every section below; `days` overrides all defaults (0 = hard clean)
all days="": (nix days) (build days) caches builder (rust days) (ios days)

# GC Nix: expire generations older than `days` (default 30), keeping the
# newest `keep` (default 3) in each profile regardless of age
nix days="" keep="":
    @{{ source_directory() }}/clean.sh nix "{{ days }}" "{{ keep }}"

# Delete Cargo/npm/Flutter build output untouched for `days` (default 0)
build days="":
    @{{ source_directory() }}/clean.sh build {{ days }}

# Delete package-manager and app caches, leaked app temp clones, and scratch
caches:
    @{{ source_directory() }}/clean.sh caches

# GC the Nix store inside OrbStack's linux-builder VM
builder:
    @{{ source_directory() }}/clean.sh builder

# Uninstall non-default Rust toolchains unused for `days` (default 7)
rust days="":
    @{{ source_directory() }}/clean.sh rust {{ days }}

# Delete old iOS sim runtimes, DerivedData, DeviceSupport > `days` (default 30)
ios days="":
    @{{ source_directory() }}/clean.sh ios {{ days }}
