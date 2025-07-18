# See: `nixos/release-small.nix`
# Keep this entry-point compatible and equivalent.
{
  ctrlos ? {
    outPath = (import ../../lib).cleanSource ./../..;
    revCount = 56789;
    shortRev = "gfedcba";
  },
  nixpkgs ? ctrlos,
  stableBranch ? false,
  # NOTE: must be equivalent to Nixpkgs supportedSystems.
  supportedSystems ? [
    "aarch64-linux"
    "x86_64-linux"
  ], # no i686-linux
  # Except for `ctrlos-ci`, which gives us the additional external checks.
  ctrlos-ci ? null
}:

let
  args = { inherit nixpkgs stableBranch supportedSystems; };
  nixos = {
    release-small = import ../../nixos/release-small.nix args;
    release = import ../../nixos/release.nix args;
  };

  # See pkgs and lib in `release-small.nix`.
  # Keep them equivalent.
  pkgs = import ./../.. { system = "x86_64-linux"; };
  lib = pkgs.lib;

  # Run through the customer checks.
  customer-checks =
    if ctrlos-ci == null then {} else
      import (ctrlos-ci + "/customers") {
      inherit
        pkgs
      ;
    }
  ;

  # We are only checking against default mainline Linux builds.
  # (Customer checks can override this.)
  kernel-generic =
    let
      all = nixos.release.tests.kernel-generic;
    in
    lib.removeAttrs
    all
    (builtins.filter (name: (builtins.match "linux_[0-9]+_[0-9]+" name) == null) (builtins.attrNames all))
  ;
in
lib.recursiveUpdate
# We run against the full release-small jobset.
nixos.release-small
# Though customize it a bit
{
  nixos = {
    # We customize a couple important NixOS checks.
    tests = {
      inherit kernel-generic;
    };
  };
  ctrlos = {
    inherit customer-checks;
    self-checks = {
      # Serves as a canary for this release jobset.
      inherit (pkgs) hello;
    };
    # We need to be aware of those extra packages.
    lix = {
      lix_2_91 = pkgs.lixVersions.lix_2_91.lix;
      lix_2_92 = pkgs.lixVersions.lix_2_92.lix;
      lix_2_93 = pkgs.lixVersions.lix_2_93.lix;
    };
  };
}
