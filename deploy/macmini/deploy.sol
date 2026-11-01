#!/usr/bin/env sol
# The live inventory: a launchd agent on the Mac mini, bound to its Tailscale
# address; nginx on the Linode is the public front (inv.cswine.cloud.nginx).
# Run from the repository root:
#
#   sol deploy/macmini/deploy.sol deploy        build, copy, back up the log, restart, probe
#   sol deploy/macmini/deploy.sol install       the same without building (ships build/inventory)
#   sol deploy/macmini/deploy.sol status        is it running, its last lines, both URLs
#   sol deploy/macmini/deploy.sol rollback      put the previous binary back and restart
#   sol deploy/macmini/deploy.sol member NAME   add a member or set a new password (asked on the Mac mini)
#   sol deploy/macmini/deploy.sol pull-data     copy the live log to data/inventory.log
#
# A deploy never edits the log: it copies it to ~/inventory/backups first
# (newest 30 kept) and keeps the replaced binary as ~/inventory/inventory.prev.
C = use "../../scripts/common".
P = use "sol/lib/proc".
H = use "sol/lib/http".

mini = "jq@jqs-mac-mini-1".
direct = "http://100.107.153.43:6720/".
public = "https://inv.cswine.cloud/".
agent = "cloud.cswine.inventory".

# stop the agent and wait until launchd has let go of it (bootstrapping over
# a job that is still going away fails with error 5)
stop = ["uid=$(id -u)",
        "launchctl bootout gui/$uid/" + agent + " 2>/dev/null || true",
        "for i in $(seq 1 50); do launchctl print gui/$uid/" + agent + " >/dev/null 2>&1 || break; sleep 0.2; done"].
start = ["launchctl bootstrap gui/$uid ~/Library/LaunchAgents/" + agent + ".plist",
         "sleep 2",
         "launchctl print gui/$uid/" + agent + " | grep -E \"state =|pid =\" || true",
         "tail -n 3 inventory.out"].
backup = ["mkdir -p backups",
          "if [ -f inventory.log ]; then cp inventory.log backups/inventory.log.$(date +%Y%m%d-%H%M%S); fi",
          "ls -t backups/inventory.log.* 2>/dev/null | tail -n +31 | xargs rm -f || true"].

# a bash script on the Mac mini, sent on ssh's stdin, its output shown as it runs
remote lines =
  script = Str.join "\n" (["set -euo pipefail", "cd ~/inventory"] + lines) + "\n";
  code = C.need (Proc.streamNow (P.withTimeout 180000 (P.withStdin script (P.spec ["ssh", mini, "/bin/bash", "-s"]))));
  C.check "the Mac mini step failed (exit {code})" (code == 0).

probe label url =
  r = Http.request (H.withDeadline 10000 H.defaultOptions) (HttpRequest "GET" url [] (Bytes.empty Unit));
  case r of
    Ok (HttpResponse status _ _) -> print "{label} {url} -> {status}"
  | Err why -> print "{label} {url} -> not answering ({why})".

probes u =
  _ = probe "direct" direct;
  probe "public" public.

atRoot u = C.check "run this from the repository root" (P.succeeded (Proc.runNow (P.spec ["/bin/test", "-f", "project.sol"]))).

build u =
  _ = C.setup Unit;
  print (C.command ["fpr", "build", "src/inventory.fpr", "-o", "build/inventory"]).

install u =
  _ = C.command ["ssh", mini, "mkdir -p ~/inventory/backups ~/Library/LaunchAgents"];
  _ = C.command ["scp", "-q", "build/inventory", mini + ":inventory/inventory.new"];
  _ = C.command ["scp", "-q", "deploy/macmini/" + agent + ".plist", mini + ":Library/LaunchAgents/" + agent + ".plist"];
  _ = remote (backup + ["if [ -f inventory ]; then cp -p inventory inventory.prev; fi", "mv inventory.new inventory"] + stop + start);
  probes Unit.

rollback u =
  remote (["if [ ! -f inventory.prev ]; then echo no inventory.prev to go back to; exit 1; fi"] + stop
          + ["mv inventory inventory.rolled-back", "mv inventory.prev inventory"] + start).

status u =
  _ = remote ["launchctl print gui/$(id -u)/" + agent + " | grep -E \"state =|pid =\" || echo not loaded",
              "ls -l inventory inventory.log", "tail -n 3 inventory.out"];
  probes Unit.

# only plain names reach the remote shell
nameCode c = (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 45 or c == 95 or c == 46.
plain name = Str.len name > 0 and List.all nameCode (Str.codes name).

member name =
  _ = C.check "a member name is letters, digits, - _ ." (plain name);
  bash = Str.join "; " (["set -e", "cd ~/inventory", "read -rsp \"new password for " + name + ": \" p", "echo"] + stop
                        + ["INV_PASSWORD=\"$p\" ./inventory --store=inventory.log --member=" + name] + start);
  C.live ["ssh", "-t", mini, "/bin/bash -c '" + bash + "'"].

pullData u =
  _ = C.setup Unit;
  _ = C.command ["scp", "-q", mini + ":inventory/inventory.log", "data/inventory.log"];
  print (C.command ["wc", "-l", "data/inventory.log"]).

> _ = atRoot Unit;
  case args Unit of
    ["deploy"] -> _ = build Unit; install Unit
  | ["install"] -> install Unit
  | ["status"] -> status Unit
  | ["rollback"] -> rollback Unit
  | ["member", name] -> _ = member name; Unit
  | ["pull-data"] -> pullData Unit
  | other -> print "Usage: sol deploy/macmini/deploy.sol deploy | install | status | rollback | member NAME | pull-data".
