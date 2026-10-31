# Inventory

A standalone household inventory with member login, locations, tags, movement history and an append-only event journal.

## Install and run

Tested with Homebrew FP-RISC 0.12.0 on macOS ARM64.

```sh
brew install hyperswine/tap/fprisc
git clone https://github.com/hyperswine/inventory.git
cd inventory
sol project.sol build
sol project.sol run --member=demo --password=change-this-demo-password
sol project.sol run --port=6720
```

Open http://127.0.0.1:6720/. Data defaults to ignored `data/inventory.log`. For real credentials prefer the `INV_PASSWORD` environment variable over a command-line password. Existing `--store`, `--page-size`, `--cache-items` and import flags remain available.

## Test

```sh
sol project.sol test
```

Native tests cover canonical tags/member names, journal create/move/delete semantics, original creation times and malformed input. The Sol integration test starts a real server on an ephemeral loopback port, verifies the HTTP page/title and cleans up the owned process.

Builds can take several minutes for the larger applications. Build/test commands have explicit deadlines and return a failure when a child process fails. Generated binaries, caches, data, keys and raw logs are excluded from Git.

## Build tools

All project orchestration and test scripts are **Sol**. There are no Makefiles, Python or Node scripts.

The application is built directly with `fpr build`; its ordinary native executable runs without Sol. Sol drives builds, tests and the optional launcher. Native builds still need Xcode Command Line Tools; standard filesystem utilities are used to prepare directories. Test HTTP requests use Sol's linked libcurl backend, with no curl executable.

## Source and license

Extracted from [hyperswine/fprisc](https://github.com/hyperswine/fprisc/tree/8a25e670b5a7edf52f1286d294b0d14d053d98dc) at `8a25e670b5a7edf52f1286d294b0d14d053d98dc`. See [ORIGIN.md](ORIGIN.md) for the source map and local changes, and [LICENSE](LICENSE) for the upstream MIT license. No existing application data, private credentials, deployed host configuration or original source checkout is required.
