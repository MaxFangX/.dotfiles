# Tinfoil Proxy: a local, attestation-verifying proxy to Tinfoil's
# confidential inference enclaves. Exposes an OpenAI-compatible endpoint
# on 127.0.0.1:3301 and seals every request to the enclave serving the
# named model, so neither Tinfoil's gateway nor any other hop can read it.
#
# Built from source rather than the upstream release binary: the proxy is
# the one component that decides whether a connection is verified, so its
# provenance should be as good as the enclave's. Pinned to a release tag.
# Update with `just update tinfoil-proxy`.
{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:
let
  source = lib.importJSON ./source.json;
in
buildGoModule {
  pname = "tinfoil-proxy";
  inherit (source) version vendorHash;

  src = fetchFromGitHub {
    owner = "tinfoilsh";
    repo = "tinfoil-proxy";
    rev = "v${source.version}";
    inherit (source) hash;
  };

  # The menu-bar app under app/ is Electron and not part of the Go build.
  subPackages = [ "." ];

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Verified local proxy to Tinfoil secure enclaves";
    homepage = "https://github.com/tinfoilsh/tinfoil-proxy";
    license = lib.licenses.mit;
    mainProgram = "tinfoil-proxy";
  };
}
