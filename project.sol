#!/usr/bin/env sol

C = use "scripts/common".

build u =
  _ = C.setup Unit;
  extra = [];
  _ = print (C.command (["fpr","build","src/inventory.fpr","-o","build/inventory"] + extra));
  Unit.

start arguments =
  _ = build Unit;
  C.live (["./build/inventory"] + arguments).

> case args Unit of
    ["build"] -> build Unit
  | "run" :: arguments -> _ = start arguments; Unit
  | ["test"] -> _ = build Unit; print (C.command ["sol","tests/check.sol"])
  | other -> print "Usage: sol project.sol build | run [application flags] | test".
