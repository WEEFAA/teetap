# ADR-0006: One POSIX sh script, curl-installed from GitHub Releases, skill bundled

**Status**: Accepted

The executable is a single `#!/bin/sh` script (no bashisms, no build step; runtime dependencies are `sh`, `tee`, `ln`, `mkdir`, `curl`, `git`). `install.sh` fetched via curl places it at `~/.local/bin/teetap` without sudo, pinned to the latest GitHub Release by default and overridable via a version environment variable — releases, not `main`, are the audit point for what users execute. The agent skill ships in the same repository and is installed by `teetap skill install`, so the script's behavior and the agent-facing documentation are versioned together and cannot drift.

## Considered options

npm/pip packaging was rejected (adds a runtime ecosystem the tool explicitly does not depend on). Homebrew was deferred, not rejected — the curl installer is the v1 channel. Curling `main` directly was rejected because an unreviewed push would change what users run.
