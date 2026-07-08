# teetap

A detachable, `tee`-based local log tap. Pipe or wrap any process — any runtime — and its output lands in one well-known directory outside your repo, where coding agents (and anyone else) can read it without owning the process. A local log aggregate built from `tee`, symlinks, and a directory.

## Usage

```sh
teetap run dev -- npm run dev        # wrap any command; output tees to the aggregate
teetap run api -- cargo run          # runtime-agnostic — not a JavaScript tool
kubectl logs -f pod | teetap pipe pod  # or pipe any stream into the sink

teetap run -d dev -- npm run dev     # detached: terminal back immediately
teetap run -d db -- docker logs -f postgres  # detach a follower: wrap it instead of piping
teetap stop dev                      # TERM, 10s grace, KILL — end marker sealed

teetap flush --older-than 6h         # delete capture files older than 6 hours
teetap flush dev                     # delete just dev.log
teetap flush --all --older-than 7d   # machine-wide sweep of stale logs

teetap path                          # where this project's logs live
teetap list                          # every tapped project on this machine, freshest first
teetap status                        # what's running, how fresh
teetap pm2 link                      # symlink PM2's existing logs into the aggregate
teetap off                           # detach and clean up
```

It taps AI-agent runtimes just as well — e.g. keep an eye on an [OpenClaw](https://openclaw.ai) assistant, local or remote, and let your coding agent triage it from the tap:

```sh
openclaw logs --follow --plain --no-color | teetap pipe assistant
openclaw logs --follow --plain --url ws://assistant-host:18789 | teetap pipe assistant-remote
```

Logs live under `~/.local/state/teetap/<project>-<hash>/`, keyed per git worktree — outside your repository, so branching, committing, and conflict resolution never touch them.

## Install

**Binary** — installs into the first directory already on your PATH and writable without sudo, so `teetap` works right away (`TEETAP_VERSION=v0.1.0` to pin a release, `TEETAP_BIN_DIR` to force a directory):

```sh
curl -fsSL https://raw.githubusercontent.com/weefaa/teetap/main/install.sh | sh
```

**Agent skill** — separate from the binary. Recommended, via the [skills.sh](https://skills.sh) ecosystem:

```sh
npx skills add https://github.com/weefaa/teetap --skill teetap
```

No-Node fallback, bundled with the binary:

```sh
teetap skill install                 # offline: embedded SKILL.md, version-locked to the binary
teetap skill install --allow-fetch   # full structure (SKILL.md + EXAMPLES.md) from the release tag
```

The skill sources live at [skills/teetap/](skills/teetap/); a test keeps the embedded copy byte-identical to [skills/teetap/SKILL.md](skills/teetap/SKILL.md) so the fallback can never drift.

### Add `~/.local/bin` to PATH manually

Only needed when the installer says so — it happens when no on-PATH directory was writable and the binary fell back to `~/.local/bin`, which macOS does not include on PATH by default (many Linux distros don't either).

**macOS** (zsh is the default shell):

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Put the line in `~/.zshenv` instead if non-interactive shells also need it — coding agents and editor tasks spawn those, and they never read `~/.zshrc`.

**Linux** (bash):

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

On Debian/Ubuntu the stock `~/.profile` already adds `~/.local/bin` when the directory exists — logging out and back in is enough.

**Windows** — teetap is a POSIX `sh` script, so it runs under WSL or Git Bash, not native PowerShell:

- **WSL**: follow the Linux instructions inside the distro.
- **Git Bash**: same line, but the file is `~/.bash_profile`:

  ```sh
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
  source ~/.bash_profile
  ```

Already-running terminals (and agent sessions, which snapshot PATH at launch) don't pick up profile edits — restart them.

## Design principles

- **Zero dependencies** beyond POSIX coreutils — one `#!/bin/sh` script.
- **The filesystem is the interface** — consumers use `tail` and `grep`, not an API.
- **Detachable** — captures live outside the repo; `off` cleans up; nothing supervises: `run -d` starts and `stop` ends, but nothing restarts or monitors.
- **Composable sources** — `tee` writes real files, PM2 joins by symlink; a source is anything that materializes a file.
- **Runtime-agnostic** — teetap moves bytes; it doesn't care what produced them.

## Automatic cleanup

teetap never runs cleanup automatically. If you want periodic flushing, compose with cron:

```sh
# flush logs older than 7 days across all projects, every night at 2am
echo '0 2 * * * teetap flush --all --older-than 7d' | crontab -
```

## License

MIT
