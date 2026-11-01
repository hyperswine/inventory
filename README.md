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

## The live deployment

The household's copy runs on the Mac mini as the launchd agent `cloud.cswine.inventory`, listening only on its Tailscale address (port 6720). nginx on the Linode terminates TLS for `inv.cswine.cloud` and proxies to it ([deploy/macmini/inv.cswine.cloud.nginx](deploy/macmini/inv.cswine.cloud.nginx) is a copy of that site). From the repository root:

```sh
sol deploy/macmini/deploy.sol deploy        # build, copy, back up the log, restart, probe both URLs
sol deploy/macmini/deploy.sol status        # running?, last lines, both URLs
sol deploy/macmini/deploy.sol rollback      # put the previous binary back
sol deploy/macmini/deploy.sol member NAME   # add a member or set a password (asked on the Mac mini, not echoed)
sol deploy/macmini/deploy.sol pull-data     # copy the live log to data/inventory.log
```

On the Mac mini, `~/inventory/inventory.log` is the inventory: one JSON line per change, never rewritten. Every deploy copies it to `~/inventory/backups/` first (newest 30 kept) and keeps the replaced binary as `inventory.prev`. The log holds password and device-token hashes, never a password or token, but it is private data: `data/` is ignored by Git.

## Build tools

All project orchestration and test scripts are **Sol**. There are no Makefiles, Python or Node scripts.

The application is built directly with `fpr build`; its ordinary native executable runs without Sol. Sol drives builds, tests and the optional launcher. Native builds still need Xcode Command Line Tools; standard filesystem utilities are used to prepare directories. Test HTTP requests use Sol's linked libcurl backend, with no curl executable.

## Source and license

Extracted from [hyperswine/fprisc](https://github.com/hyperswine/fprisc/tree/8a25e670b5a7edf52f1286d294b0d14d053d98dc) at `8a25e670b5a7edf52f1286d294b0d14d053d98dc`. See [ORIGIN.md](ORIGIN.md) for the source map and local changes, and [LICENSE](LICENSE) for the upstream MIT license. No existing application data, private credentials, deployed host configuration or original source checkout is required.
