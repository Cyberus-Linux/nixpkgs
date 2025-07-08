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
  };
in
# Keep sorted, use complete attribute paths.
{
}
