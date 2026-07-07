# ADR-0005: Process-manager sources join by symlink, never by re-teeing

**Status**: Accepted

PM2 already tees every managed process to `~/.pm2/logs/<name>-out.log` / `-error.log`. `teetap pm2 link` symlinks those files into the project directory with a `pm2-` filename prefix (all running processes by default, filterable, idempotent on re-run). Output is never re-piped: re-teeing would duplicate every byte, require a long-running extra process, and create a second, laggier source of truth.

PM2 is a bundled source integration, not a core concept — the pattern (link what already exists, tee what doesn't) generalizes to any future source.

## Consequences

Linked entries are only as fresh as the last `pm2 link` run; adding a new PM2 app requires re-running it. `teetap off` removes symlinks unconditionally since targets are never touched. Consumers can distinguish source type from the filename prefix (or `teetap status`) without a manifest.
