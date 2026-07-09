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

    system.defaultChannel =
      mkDistroOverride "https://channels.ctrl-os.com/channel/ctrlos-${config.system.nixos.release}.tar.xz";

    nix.settings = {
      trusted-public-keys = [
        "ctrl-os:baPzGxj33zp/P+GAIJXsr8ss9Law+qEEFViX1+flbv8="
      ];

      substituters = [
        "https://cache.ctrl-os.com/"
      ];
    };
  };
}
