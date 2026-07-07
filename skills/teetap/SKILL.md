---
name: teetap
description: Read the developer's local process logs (dev servers, PM2 workers, any piped stream) without owning the process. Use when debugging local behavior, when asked to "check the logs", "watch the server", "what happened when I...", or when you need runtime output you did not start yourself.
---

# teetap — read local process logs you don't own

The developer taps their processes with `teetap`; output lands in one
directory per project, outside the repo. You read it with tail/grep.

## Quick start

```sh
DIR=$(teetap path)     # this project's log directory (never derive it yourself)
teetap status          # NAME TYPE BYTES AGE_S — what's tapped, how fresh
tail -50 "$DIR"/dev.log
```

**If `teetap status` shows nothing (or the directory is empty), the
developer has not plugged in — say so and stop. Do not hunt the
filesystem for logs.**

## Reading a log correctly

Files append across runs. Every run is bracketed by marker lines:

```
===== teetap session <id> start <time> name=dev branch=... cwd=... pid=... =====
===== teetap session <id> end <time> name=dev exit=0 =====
```

Scope your reading to the CURRENT run — everything after the last start
marker. Errors before it belong to a previous session:

```sh
awk '/teetap session .* start/{n=NR} {l[NR]=$0} END{for(i=n;i<=NR;i++) print l[i]}' "$DIR"/dev.log
```

An `exit=` value in the end marker is the wrapped command's exit code.

## Querying — treat the directory like a log store

Prefer `grep`/`sed`/`awk` over reading whole files: they are your query
language, and they compose into anything a hosted log store can answer.
Never dump a large log into context — query it down first.

```sh
grep -h "<request-id>" "$DIR"/*.log            # one identifier across ALL sources
grep -n  "ERROR\|error" "$DIR"/dev.log         # find errors, keep line numbers
sed -n '/13:18:00/,/13:18:30/p' "$DIR"/dev.log # time-range slice
```

Chain them like query stages: filter (`grep`) → slice (`sed -n 'X,Yp'`)
→ project/aggregate (`awk`, `sort | uniq -c | sort -rn`).

`EXAMPLES.md` next to this file (present when installed via
`npx skills add` or `teetap skill install --allow-fetch`) has the full
recipe collection and end-to-end walkthroughs; without it, compose the
three recipes above.

**What is running right now?** `teetap status` — `AGE_S` near 0 means
actively writing; large means idle or stopped. PM2 workers appear as
`pm2-<process>.log` symlinks — same directory, same queries.

**Previous run:** `<name>.prev.log` (exists only if the developer used
`--rotate`); split sessions are `<name>.<session-id>.log`.

## Advanced

Suggest taps to the developer (they run these, not you):

```sh
teetap run dev -- <any command>        # wrap: tees + records exit code
<producer> 2>&1 | teetap pipe <name>   # sink: tap any stream
teetap pm2 link                        # add PM2 logs to the aggregate
teetap off                             # detach when done
```

Full command reference: `man teetap` or `teetap --help`.
