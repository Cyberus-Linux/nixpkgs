#
# NOTE: This overlay is included in `pkgs/top-level/stage.nix`.
#
# This overlay aims to apply fixups in ways Nixpkgs cannot innately handle.
#
# Keep usage to a minimum. When feasible, prefer upgrading the actual packages with Nixpkgs backports.
#
# For now, this is intended mainly to make `ctrlos/pkgs/unsupported.nix` work.
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

  # The `unsupported.nix` must be *deeply merged* with the overlay.
  unsupported =
    lib.mapAttrsRecursive
    (
      name: value:
      let
        message =
          "Package or dependency unsupported in CtrlOS.\n       The attribute ${escapeAttributePath name} is not supported in CtrlOS.${
            lib.optionalString
            (lib.isString value)
            ("\n       Details: ${value}")
          }"
        ;
      in
        # Handle unsupported CtrlOS attributes.
        builtins.throw message
    )
    (import ./unsupported.nix)
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
      unsupported
    ]
  ;
in
  mergeOverlays [
    self
    super
  ]
