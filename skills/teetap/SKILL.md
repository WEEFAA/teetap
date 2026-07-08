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

If `teetap status` shows nothing here, the logs may belong to a project
tapped from another directory — see "Choosing the project" below.

## Choosing the project

When this directory has no tap, consult the registry (never hunt the
filesystem outside teetap's own directory):

```sh
teetap list            # PROJECT  PATH  SOURCES  AGE_S — most recent first
```

- **0 rows** — the developer has not plugged in anywhere. Say so and stop.
- **1 row** — use it, stating the assumption: "Using PROJECT (PATH), the
  only tapped project."
- **2+ rows** — recommend one, then ASK the user; never silently pick.
  Rank candidates by: (1) path affinity — PATH is an ancestor, descendant,
  or sibling worktree of your cwd; (2) recency — smallest AGE_S;
  (3) name match against the user's words.

Then read from the chosen row's directory:

```sh
DIR="${TEETAP_DIR:-$HOME/.local/state/teetap}/PROJECT"
```

If `teetap list` fails as an unknown command, the installed binary
predates it — ask the developer to re-run the install one-liner instead
of improvising.

## Reading a log correctly

Files append across runs. Every run is bracketed by marker lines:

```
===== teetap session <id> start <time> name=dev branch=... cwd=... pid=... =====
===== teetap session <id> end <time> name=dev exit=0 =====
```

Scope your reading to the CURRENT run — everything after the last start
marker. Errors before it belong to a previous session:

```sh
tail -n "+$(grep -n 'teetap session .* start' "$DIR"/dev.log | tail -1 | cut -d: -f1)" "$DIR"/dev.log
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

## Stale log advisory

After running `teetap status`, check `AGE_S` for every source. If any
file looks stale, advise the developer to flush it.

**Deriving the threshold:** the minimum recommended age is **4 hours**
(14400 seconds). Derive a project-appropriate threshold from what you
observe — a dev server that restarts every few minutes makes logs stale
faster than a long-running worker. Use your judgement, but never
recommend below 4h.

When you spot stale files, ask the developer — never flush silently:

> Some logs look stale (dev.log last written 18h ago). Want me to flush
> them? I'd suggest: `teetap flush --older-than 6h`

Adjust the `--older-than` value to your derived threshold.

## Flushing logs

`flush` deletes capture files without detaching the project:

```sh
teetap flush                           # all capture files in this project
teetap flush dev                       # just dev.log
teetap flush --older-than 6h           # only files not written to in 6h
teetap flush --older-than 7d --all     # machine-wide, stale files only
```

Age format: `<number><unit>` — `m` (minutes), `h` (hours), `d` (days).

Rules you should know:
- **Live detached processes are always skipped** — flush will tell you to
  `teetap stop <name>` first. Never try to force past this.
- **Symlinks (PM2 links) are always skipped** — flush clears data, not
  wiring. `teetap off` removes symlinks.
- **The project directory survives** — after flush, the project is still
  plugged in and visible in `teetap list`.

## Advanced

Suggest taps to the developer (they run these, not you):

```sh
teetap run dev -- <any command>        # wrap: tees + records exit code
teetap run -d dev -- <any command>     # detached: terminal back immediately
<producer> 2>&1 | teetap pipe <name>   # sink: tap any stream
teetap pm2 link                        # add PM2 logs to the aggregate
teetap stop dev                       # end a detached tap
teetap off                             # detach when done
```

Full command reference: `man teetap` or `teetap --help`.
