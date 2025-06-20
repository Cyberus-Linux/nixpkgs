CtrlOS CI
=========

### Verifying changes locally without setting up a Hydra.

A checkout of the CtrlOS `CI/hydra-declarative-jobset` branch will be needed to fully verify changes.
If it is missing, the customer checks will be empty (though the rest will evaluate properly).

```
 $ nix-shell -p nix-eval-jobs
 $ nix-eval-jobs ./ctrlos/ci/ci.nix --force-recurse --arg ctrlos-ci ../ctrlos-ci-declarative-jobset
```
