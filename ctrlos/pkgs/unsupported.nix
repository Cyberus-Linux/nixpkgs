# Attribute paths removed from CtrlOS.
# Null values use only the default message.
# String values are added to default message as explanations.
# Keep this sorted.
#
# Why is this not into `pkgs/top-level/aliases.nix`?
# Because we want those to provide valid attributes when using `allowAliases = false`.
# This prevents churn by soft-removing packages without removing the whole dependents chain.
# The dependents of removed packages may be updated later down the line.
let
  messages = {
    # Generic messages
    unstableVersion = "No support for unstable package versions.";

    # Ecosystem or package-specific messages
    nixStable = "Nix 2.24 is the only currently supported Nix version.";
  };
in
# Keep sorted, use complete attribute paths.
{
  nixVersions.git = messages.unstableVersion;
  nixVersions.nix_2_18 = messages.nixStable;
  nixVersions.nix_2_19 = messages.nixStable;
  nixVersions.nix_2_20 = messages.nixStable;
  nixVersions.nix_2_21 = messages.nixStable;
  nixVersions.nix_2_22 = messages.nixStable;
  nixVersions.nix_2_23 = messages.nixStable;
}
