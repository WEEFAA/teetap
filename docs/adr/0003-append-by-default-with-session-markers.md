# ADR-0003: Append by default, with in-file session markers; flags change the lifecycle

**Status**: Accepted

Re-running a capture appends to the existing `<name>.log`. Every session stamps a start marker line (monotonic session id, timestamp, name, git branch, cwd, pid) and an end marker (exit code when known). Markers are what make append viable: an agent scopes its reading to the last start marker, so stale errors from a previous run are never mistaken for live ones. Lifecycle flags override the default: `--rotate` keeps exactly one previous generation (`<name>.prev.log`), `--truncate` clobbers, `--split` writes one file per session.

## Considered options

Truncate-by-default (plain `tee` behavior) loses the previous run — often the crash being debugged — at the moment of restart. Timestamped files per run never lose anything but grow unboundedly and force consumers to locate "the current file." Rotate-by-default was the original recommendation; append was chosen by the owner as the least surprising default, with the others one flag away.
