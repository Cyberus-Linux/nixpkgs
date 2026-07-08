{ config, lib, ... }:
let
  mkDistroOverride = lib.mkOverride 1400;
in
{
  config = {
    system.nixos = lib.attrsets.mapAttrs (_: mkDistroOverride) {
      vendorName = "Cyberus Technology GmbH";

      distroName = "CTRL-OS";
      distroId = "ctrl-os";
    };
  };
}
