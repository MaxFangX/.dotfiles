{
  fetchFromGitHub,
  fetchurl,
  lib,
  stdenv,
  versionCheckHook,
}:
let
  sources = lib.importJSON ./sources.json;
  # Linux uses the static musl builds, so no patching is needed.
  source = sources.${stdenv.hostPlatform.system};

  # Only for the `skills/` and `skill-data/` dirs.
  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-browser";
    tag = "v${sources.version}";
    hash = sources.srcHash;
  };
in
stdenv.mkDerivation {
  pname = "agent-browser";
  inherit (sources) version;

  dontUnpack = true;
  dontBuild = true;

  # `agent-browser skills` looks for `skills/` and `skill-data/` in the
  # parent of the canonicalized exe's dir. See cli/src/skills.rs.
  installPhase = ''
    runHook preInstall
    install -Dm 755 ${fetchurl { inherit (source) url hash; }} \
      $out/bin/agent-browser
    cp -r ${src}/skills ${src}/skill-data $out/
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Browser automation CLI for AI agents";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = lib.licenses.asl20;
    mainProgram = "agent-browser";
    platforms = builtins.attrNames
      (removeAttrs sources [ "version" "srcHash" ]);
  };
}
