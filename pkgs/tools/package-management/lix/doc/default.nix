{
  src,
  rustPlatform,
  version,
  cargoDeps,
}:

rustPlatform.buildRustPackage {
  pname = "lix-doc";
  sourceRoot = "${src.name or src}/lix-doc";
  inherit
    version
    src
    cargoDeps
    ;

  # nixos-unstable backport compat
  cargoHash = cargoDeps.hash;
}
