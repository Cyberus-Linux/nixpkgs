let
  pinnedNixpkgs = builtins.fromJSON (builtins.readFile ./pinned-nixpkgs.json);
in
{
  system ? builtins.currentSystem,

  nixpkgs ? null,
}:
let
  nixpkgs' =
    if nixpkgs == null then
      fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${pinnedNixpkgs.rev}.tar.gz";
        sha256 = pinnedNixpkgs.sha256;
      }
    else
      nixpkgs;

  pkgs = import nixpkgs' {
    inherit system;
    config = {
      permittedInsecurePackages = [ "nix-2.3.18" ];
    };
    overlays = [ ];
  };
in
{
  inherit pkgs;
  requestReviews = pkgs.callPackage ./request-reviews { };
  codeownersValidator = pkgs.callPackage ./codeowners-validator { };
}
