# ADR-0001: The aggregate is a directory; the interface is the filesystem

**Status**: Accepted

Consumers (agents, humans, scripts) need one well-known place to see everything a developer is running locally. We decided the aggregate is a plain directory of log files — real files written by `tee`, symlinks for sources that already write files — read with ordinary `tail`/`grep`/`ls`. No manifest, no daemon, no reader API.

## Considered options

A JSON manifest listing sources with metadata was rejected: every consumer would need a parser, and the filesystem already carries the needed metadata (name, size, mtime, symlink target). A long-running aggregator process was rejected as violating the zero-dependency, no-daemon criteria.

## Consequences

Composability falls out for free: a "source" is anything that materializes a file into the directory. Rich per-source metadata (branch, pid, exit code) must therefore live inside the files as marker lines, not in a sidecar database.
