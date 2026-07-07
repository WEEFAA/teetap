# ADR-0002: Logs live outside the repo, scoped per git worktree

**Status**: Accepted

Log directories live under `~/.local/state/teetap/` (overridable via `TEETAP_DIR`), one directory per project keyed by `<basename>-<short-hash>` of the git toplevel's absolute path. Because captures are outside the repository, branching, committing, conflict resolution, and file moves can never interact with them — the "detachable during git operations" requirement is satisfied by placement rather than by teardown machinery.

Branch switches within a checkout keep the same directory (same toplevel path); separate worktrees get separate directories, which is correct because they run separate processes. The basename keeps directories human-readable; the hash disambiguates same-named checkouts.

## Considered options

Per-agent or per-session directory namespaces were considered and removed: the default lifecycle is append (a stable file path across runs), cross-agent visibility was an explicit goal, and coupling the tool to agent identity fights the independence criterion. Sessions are tracked inside files instead (ADR-0003).
