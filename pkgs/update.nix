# Run all updateScripts:  nix-shell pkgs/update.nix
# Run one:                nix-shell pkgs/update.nix --argstr package codex
{
  package ? null,
}:
let
  dotfiles = import ../. { };
  inherit (dotfiles) lib pkgs;

  # All custom packages with an updateScript.
  updatable = lib.filterAttrs (
    _: pkg:
    lib.isDerivation pkg
    && pkg ? updateScript
  ) {
    inherit (dotfiles) claude-code codex omnara;
  };

  packages =
    if package != null then
      let
        pkg = updatable.${package}
          or (throw "'${package}' not found");
      in
      { ${package} = pkg; }
    else
      updatable;

  getUpdateScript = pkg:
    map builtins.toString
      (lib.toList (pkg.updateScript.command
        or pkg.updateScript));

  packageData = lib.mapAttrsToList (name: pkg: {
    inherit name;
    pname = lib.getName pkg;
    oldVersion = lib.getVersion pkg;
    updateScript = getUpdateScript pkg;
  }) packages;

  packagesJson = pkgs.writeText "packages.json"
    (builtins.toJSON packageData);
in
pkgs.mkShellNoCC {
  packages = [ pkgs.jq ];
  shellHook = ''
    exec ${./update.sh} ${packagesJson}
  '';
}
