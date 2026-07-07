# teetap

A detachable, `tee`-based local log tap. Pipe or wrap any process — any runtime — and its output lands in one well-known directory outside your repo, where coding agents (and anyone else) can read it without owning the process. A local log aggregate built from `tee`, symlinks, and a directory.

The full specification lives in [docs/prd/PRD-teetap.md](docs/prd/PRD-teetap.md); architecture decisions in [docs/adr/](docs/adr/).

## Usage

```sh
teetap run dev -- npm run dev        # wrap any command; output tees to the aggregate
teetap run api -- cargo run          # runtime-agnostic — not a JavaScript tool
kubectl logs -f pod | teetap pipe pod  # or pipe any stream into the sink

teetap path                          # where this project's logs live
teetap status                        # what's running, how fresh
teetap pm2 link                      # symlink PM2's existing logs into the aggregate
teetap off                           # detach and clean up
```

Logs live under `~/.local/state/teetap/<project>-<hash>/`, keyed per git worktree — outside your repository, so branching, committing, and conflict resolution never touch them.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/weefaa/teetap/main/install.sh | sh
teetap skill install   # give your coding agents the /teetap skill
```

Installs the single script to `~/.local/bin/teetap`, pinned to the latest GitHub Release (`TEETAP_VERSION=v0.1.0` to pin). The `/teetap` agent skill is embedded in the script itself, so tool and skill can never drift.

## Design principles

- **Zero dependencies** beyond POSIX coreutils — one `#!/bin/sh` script.
- **The filesystem is the interface** — consumers use `tail` and `grep`, not an API.
- **Detachable** — captures live outside the repo; `off` cleans up; nothing daemonizes.
- **Composable sources** — `tee` writes real files, PM2 joins by symlink; a source is anything that materializes a file.
- **Runtime-agnostic** — teetap moves bytes; it doesn't care what produced them.

## License

MIT
