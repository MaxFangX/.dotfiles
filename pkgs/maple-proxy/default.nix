# Maple Proxy: a local, attestation-verifying proxy to Maple's (OpenSecret)
# confidential inference enclaves. Exposes an OpenAI-compatible endpoint
# and encrypts every request to an AWS Nitro enclave it has verified
# against Maple's PCR0 trust roots, so no hop in between can read it.
#
# Built from source rather than the upstream release binary: the proxy is
# the one component that decides whether a connection is verified, so its
# provenance should be as good as the enclave's. The proxy lives in the
# Maple monorepo and patches `maple-sdk` to the in-tree crate, so the
# checkout needs both `proxy/` and `sdk/rust/`. Pinned to a Maple release
# tag. Update with `just update maple-proxy`.
{
  fetchFromGitHub,
  lib,
  rustPlatform,
}:
let
  source = lib.importJSON ./source.json;
in
rustPlatform.buildRustPackage {
  pname = "maple-proxy";
  inherit (source) version cargoHash;

  src = fetchFromGitHub {
    owner = "MaplePrivacyLabs";
    repo = "Maple";
    rev = "v${source.version}";
    sparseCheckout = [
      "proxy"
      "sdk/rust"
    ];
    inherit (source) hash;
  };
  sourceRoot = "source/proxy";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Verified local proxy to Maple confidential AI enclaves";
    homepage = "https://github.com/MaplePrivacyLabs/Maple/tree/master/proxy";
    license = lib.licenses.mit;
    mainProgram = "maple-proxy";
  };
}
