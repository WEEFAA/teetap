# ADR-0007: Detached run, no supervision

**Status**: Accepted

`teetap run -d <name> -- <cmd>` starts the wrapped command detached — the terminal is free immediately, the capture survives terminal close — and prints the pid and log path. `teetap stop [-t <seconds>] <name>` ends it: SIGTERM, a grace period (default 10s, Docker's contract), then SIGKILL. The boundary is starts-and-stops, never manages: no restarts on crash, no health checks, no process table. The README principle accordingly narrows from "nothing daemonizes" to "nothing supervises" — a detached tap is a background child with a pidfile, not a daemon with a manager.

Session-marker discipline (ADR-0003) holds in detached mode: a wrapper process outlives the invocation, forwards TERM to the producer, and writes the end marker with the real exit code whether the producer exits, crashes, or is stopped. The started signal is deliberately separate from the liveness signal (the pidfile): a fast-exiting producer seals its session — removing the pidfile — before the parent ever polls, so the parent reads the pid from a one-shot handoff file instead.

The verbs keep disjoint contracts: `stop` ends processes, `off` cleans files. `off` never kills — a tap whose detached command is alive is skipped even with `--force`, with a pointer to `stop`. `run -d` refuses a name whose command is still running (Docker's name-conflict behavior). `status` shows a live detached tap as TYPE `run` — an additive value alongside `tee`/`link`, no column change, so the skill's documented output contract survives. Pidfiles are dotfiles in the project directory, invisible to the `"$dir"/*` globs like the `.teetap-project` breadcrumb.

`pipe` gets no `-d`: in `producer | teetap pipe <name>` the producer lives in the caller's shell, so teetap detaching its own half would leave the producer bound to the terminal anyway — a broken promise. The rule of thumb: when you want the terminal back, teetap must be the parent of the producer, not the tail of its pipeline (`teetap run -d pod -- kubectl logs -f pod`).

## Considered options

A light supervisor (restart-on-crash, `ps` table) was rejected: it reinvents pm2 and contradicts ADR-0005's rationale for never re-teeing managed processes. Documenting shell composition only (`nohup ... &`) was rejected: it leaves the lifecycle tedium — finding, stopping, HUP-proofing — that motivated the feature. A separate verb (`start`/`spawn`) was rejected in favor of Docker's familiar `run -d`.
