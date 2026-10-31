# Extraction provenance

Upstream: https://github.com/hyperswine/fprisc

Application revision: `8a25e670b5a7edf52f1286d294b0d14d053d98dc`.

Application inputs:

- `examples/inventory.fpr`

Local changes:

- Package the application in its own repository and retain its original behavior.
- Add Sol build/launch/test orchestration and isolated, ignored data directories.
- Resolve app-local imports within this repository and standard modules through installed toolchain homes.
- Default persistent application files to `data/`; preserve explicit path flags.

Generated artifacts and test captures are not upstream source; reports identify the checks actually run.
