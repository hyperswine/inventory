#!/usr/bin/env sol

C = use "../scripts/common".
W = use "../scripts/webtest".
J = use "sol/lib/json".

runChecks u =
  _ = C.setup Unit;
  _ = C.command ["fpr","build","tests/check.fpr","-o","build/check"];
  scratch = tempDir "inventory-test";
  output = C.command (["./build/check"] + []);
  _ = C.check "native checks failed" (Str.contains "inventory checks passed" output and not (Str.contains "FAIL" output));
  _ = print output;
  root = C.need (IO.cwd Unit);
  job = W.start ["{root}/build/inventory","--port=0","--address=127.0.0.1","--store={scratch}/app.log"] scratch "{scratch}/server.log";
  _ = sleepMs 300;
  port = W.ready "{scratch}/server.log" "ready " 300;
  page = W.get "http://127.0.0.1:{port}/";
  _ = C.check "application HTTP page failed" (W.status page == 200 and Str.contains "Home inventory" (W.body page));
  _ = C.need (Proc.cancel job);
  _ = C.writeText "evidence/native-checks.log" output;
  C.report
    "evidence/results.json"
    (J.JObj [("passed",J.JBool True),("runner",J.JStr "Sol"),
      ("checks",J.JArr [J.JStr "native application behavior",J.JStr "real loopback HTTP 200",J.JStr "application title",J.JStr "owned server cleanup"]),
      ("compiler",J.JStr (Str.trim (C.command ["fpr","--version"]))) ]).

> runChecks Unit.
