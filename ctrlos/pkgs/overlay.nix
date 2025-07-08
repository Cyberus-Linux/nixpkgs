#
# NOTE: This overlay is included in `pkgs/top-level/stage.nix`.
#
# This overlay aims to apply fixups in ways Nixpkgs cannot innately handle.
#
# Keep usage to a minimum. When feasible, prefer upgrading the actual packages with Nixpkgs backports.
#
final: super:
let
  inherit (super) lib;

  recursiveUpdateAll =
    lib.foldl
    lib.recursiveUpdate
    {}
  ;
  escapeAttributePath =
    path:
    lib.concatMapStringsSep "." lib.strings.escapeNixIdentifier path
  ;

  # Merge package sets (attribute sets) by merging their attribute sets.
  mergeOverlays =
    lib.zipAttrsWith
    (name: values:
      if builtins.length values == 1 then
        builtins.head values
      else
        recursiveUpdateAll values
    )
  ;

  overlay =
    {
      # Canary value for quick checks.
      ctrlos = {
        version = "24.05";
      };
    }
  ;

  self =
    mergeOverlays [
      overlay
    ]
  ;
in
  mergeOverlays [
    self
    super
  ]
