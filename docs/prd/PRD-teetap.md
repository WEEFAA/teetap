# PRD: teetap — a detachable, tee-based local log tap for agents

**Status:** ready-for-agent

## Problem Statement

When a developer runs local servers in a terminal (any runtime — Node, Python, Go, Rust, anything), coding agents cannot see that output without owning the process. Debugging with an agent means copy-pasting log excerpts by hand. Process managers like PM2 already write log files, but foreground dev servers write only to the terminal, and there is no single, well-known place an agent can look to see "everything I am running right now" — a local equivalent of an SLS log aggregate.

The capture mechanism must also be **detachable**: it must never entangle itself with the developer's repository, so branching, committing, resolving conflicts, and moving files can proceed without tearing anything down or corrupting captured logs.

## Solution

`teetap`: a single dependency-free POSIX shell executable plus a companion agent skill.

The developer pipes or wraps their processes through `teetap`, which `tee`s output to a well-known per-project directory **outside the repository**. Any agent (or any observer) reads that directory with ordinary `tail`/`grep` — no process ownership, no daemon, no protocol. PM2-managed processes join the same aggregate via symlinks to the log files PM2 already writes. The bundled skill teaches agents the conventions so every agent inspects logs the same way.

## User Stories

1. As a developer, I want my foreground dev server's output captured to a file while still seeing it live in my terminal, so that capture costs me nothing.
2. As a developer, I want to wrap any command regardless of language or runtime, so that the tool is not coupled to one ecosystem.
3. As a developer, I want to pipe any stream into the tap (a filtered pipeline, a remote tail over ssh, a container log), so that unusual producers are first-class, not workarounds.
4. As a developer, I want captured logs stored outside my repository, so that branching, committing, conflict resolution, and file moves never interact with them.
5. As a developer, I want one command to detach and clean up, so that plugging off is as easy as plugging in.
6. As a developer, I want detach to refuse to delete a file that looks actively written (unless forced), so that I cannot silently sever a live capture.
7. As a developer, I want my PM2-managed processes visible in the same aggregate without duplicating their output, so that one directory shows everything I am running.
8. As a developer, I want re-running a capture to append by default with a clear session boundary, so that history is preserved and runs remain distinguishable.
9. As a developer, I want opt-in flags to rotate, truncate, or split into a new file per run, so that I control file lifecycle when the default does not fit.
10. As a developer, I want to install the tool with a single curl command and no sudo, so that setup takes seconds on any machine.
11. As a developer, I want installs pinned to released versions, so that what I run is auditable and reproducible.
12. As an agent, I want one command that prints the current project's log directory, so that I never re-derive the directory convention myself.
13. As an agent, I want one command that lists each log source with its type, size, and freshness, so that I can tell what is running without interpreting directory listings.
14. As an agent, I want session-start and session-end markers inside appended files, so that I can scope my reading to the current run and not confuse stale errors with live ones.
15. As an agent, I want an empty or absent project directory to mean "the developer has not plugged in," so that I stop there instead of hunting the filesystem for logs.
16. As an agent working in one worktree, I want to see only that worktree's processes, so that two checkouts running side by side do not blur together.
17. As a supervising agent, I want to glob across all project directories, so that I can see everything the developer is doing machine-wide, like a log aggregate.
18. As a second/other agent, I want the same skill conventions available to me, so that every agent inspects logs identically without rediscovering the tool.
19. As a maintainer, I want the executable to be a single POSIX sh script with zero runtime dependencies beyond coreutils, so that it runs identically on macOS, Linux, and slim CI images.
20. As a maintainer, I want the skill versioned and shipped with the script, so that agent-facing documentation never drifts from tool behavior.

## Implementation Decisions

- **Two deliverables, one repo, one version.** A single POSIX `sh` executable named `teetap`, and an agent skill named `teetap` bundled in the same repository and installed by the tool itself (`teetap skill install`). The skill can never drift from the script because they ship together.
- **The aggregate is a directory; the interface is the filesystem.** Root `~/.local/state/teetap/` (XDG state), overridable via the `TEETAP_DIR` environment variable. No manifest, no daemon, no reader API — consumers use `tail`, `grep`, `ls`.
- **Per-worktree project scoping.** Each project directory is keyed by the git toplevel of the current working directory: `<basename>-<short-hash-of-absolute-path>`. Same checkout across branches → same directory; separate worktrees → separate directories. No per-agent or per-session namespaces. Outside a git repo, the key falls back to the cwd itself.
- **`teetap pipe <name>` is the capture primitive.** It reads stdin, stamps a session-start marker, appends through `tee` to `<name>.log` in the project directory while passing lines through to stdout, and stamps a session-end marker on EOF. It accepts any stream from any producer.
- **`teetap run [flags] <name> -- <cmd>` is sugar over `pipe`.** It merges stderr into stdout, feeds the command through the pipe path, and enriches markers with the command line and exit code. No default command is assumed — the tool is runtime-agnostic by design.
- **Append is the default lifecycle; flags change it.** `--rotate` moves the existing log to `<name>.prev.log` and starts fresh (exactly one previous generation); `--truncate` clobbers in place; `--split` writes a new `<name>.<session-id>.log` per run.
- **Session markers make append viable.** Every session writes a start marker line carrying a monotonic session id, ISO timestamp, name, git branch, cwd, and pid, and an end marker on termination (with exit code when known). Agents scope reads to the last start marker.
- **PM2 is a bundled source integration, not a core concept.** `teetap pm2 link [names…]` symlinks PM2's existing per-process log files into the project directory with a `pm2-` filename prefix; all running PM2 processes by default, filterable by name; idempotent re-runs add new apps and prune dead links. PM2 output is never re-piped or duplicated. Other source integrations can follow the same pattern: anything that materializes a file into the directory is a source.
- **Detach is `teetap off [--force]`.** Symlinks are removed unconditionally (targets untouched). Real capture files with a recent modification time are treated as live: skipped with a warning unless `--force`. Stopping a live producer is the developer's job; `off` cleans up afterwards.
- **Introspection commands.** `teetap path` prints the resolved project directory for the cwd (the single implementation of the naming convention). `teetap status` lists each source with its type (tee file vs pm2 link), size, and seconds since last write.
- **Distribution.** `install.sh` fetched via curl installs the script (no sudo, ever) into the first directory already on `$PATH` and user-writable — `~/.local/bin`, `/opt/homebrew/bin`, `/usr/local/bin` — falling back to `~/.local/bin` with a PATH warning. Pinned to the latest GitHub Release by default and overridable with a version environment variable. Old copies in other candidate directories are warned about, never deleted.
- **Detached capture.** `teetap run -d <name> -- <cmd>` starts the wrapped command detached (terminal free immediately, survives terminal close, pid and log path printed); `teetap stop [-t <seconds>] <name>` ends it with TERM → grace (default 10s) → KILL. Session markers hold in both modes. `stop` ends processes; `off` cleans files and never kills. No supervision: nothing restarts on crash, nothing is monitored.
- **Deliberate omissions.** No reader subcommands (`tail`/`grep` wrappers), no supervision or restarts (detached commands are started and stopped, never managed), no log rotation beyond `--rotate`, no npm/pip packaging, no agent-identity coupling, no re-teeing of process-manager output.

## Testing Decisions

- **The executable is the test seam.** Tests invoke `teetap` subcommands black-box against a sandbox directory (`TEETAP_DIR` pointed at a temp dir) and assert on externally observable results: files created, marker lines present and well-formed, stdout passthrough intact, exit codes, symlink targets, `status`/`path` output. No test reaches into function internals.
- **Behaviors covered:** `pipe` writes and passes through; markers open and close a session; `run` records exit codes and merges stderr; append vs `--rotate` vs `--truncate` vs `--split` lifecycles; `path` determinism (same cwd → same dir; different worktrees → different dirs); `pm2 link` idempotence with a faked PM2 log directory; `off` mtime guard and `--force`; empty-dir semantics.
- **Harness:** a plain POSIX sh test runner in the repository (no bats, no framework — consistent with the zero-dependency criterion) plus `shellcheck` linting. Both run in CI on Linux and macOS.
- **What makes a good test here:** it would still pass if the script were rewritten from scratch against the same command surface and file conventions.

## Out of Scope

- Capturing output of processes that cannot be piped or wrapped (attaching to arbitrary running PIDs).
- Log shipping, remote aggregation, retention policies, or rotation daemons.
- Windows support (POSIX environments only; WSL works).
- Structured/JSON log parsing — teetap moves bytes; interpretation belongs to consumers.
- Claude/agent session identity integration (deliberately removed during design).
- Homebrew packaging (may follow later; curl installer is the v1 channel).

## Further Notes

- Architecture decisions and their rationale are recorded as ADRs under the docs directory: filesystem-as-interface, per-worktree scoping, append-with-markers, pipe-as-primitive, symlink sources, and single-script distribution.
- The skill follows the write-a-skill conventions: trigger-keyword description; quick start (`teetap path` → `teetap status` → tail/grep from the last session marker); workflows for correlating across sources; `pipe` documented under advanced usage; "empty directory means not plugged in — stop hunting" stated explicitly.
- Naming: the repo, the executable, and the skill are all `teetap`, so the name a user types is the name an agent loads.
