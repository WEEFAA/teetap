#!/bin/sh
# teetap installer: downloads the pinned release script to a directory
# that is already on PATH, so `teetap` resolves without shell restarts.
#   curl -fsSL https://raw.githubusercontent.com/OWNER/teetap/main/install.sh | sh
#   TEETAP_VERSION=v0.1.0 sh install.sh   # pin a specific release
set -eu

REPO="${TEETAP_REPO:-weefaa/teetap}"
CANDIDATES="${TEETAP_BIN_CANDIDATES:-$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin}"

on_path() {
    case ":$PATH:" in *":$1:"*) return 0 ;; *) return 1 ;; esac
}

# First candidate already on PATH and writable without sudo; the first
# candidate may not exist yet (mkdir -p creates it). Falls back to the
# first candidate, which triggers the add-to-PATH note below.
pick_bin_dir() {
    saved_ifs=$IFS; IFS=:
    set -- $CANDIDATES
    IFS=$saved_ifs
    fallback=$1
    for dir; do
        on_path "$dir" || continue
        if [ -d "$dir" ] && [ -w "$dir" ]; then printf '%s\n' "$dir"; return; fi
        if [ "$dir" = "$fallback" ] && [ ! -e "$dir" ]; then printf '%s\n' "$dir"; return; fi
    done
    printf '%s\n' "$fallback"
}

BIN_DIR="${TEETAP_BIN_DIR:-$(pick_bin_dir)}"

version="${TEETAP_VERSION:-}"
if [ -z "$version" ]; then
    # Resolve the tag from the releases/latest redirect: unlike api.github.com,
    # the web endpoint is not rate-limited for anonymous callers.
    version=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest" \
        | sed 's|.*/releases/tag/||')
fi
case "$version" in
    ''|*/*) echo "teetap install: could not resolve a release for $REPO (does one exist?)" >&2; exit 1 ;;
esac

mkdir -p "$BIN_DIR"
curl -fsSL "https://raw.githubusercontent.com/$REPO/$version/teetap" -o "$BIN_DIR/teetap"
chmod +x "$BIN_DIR/teetap"

# man(1) derives its search path from PATH: <prefix>/bin -> <prefix>/share/man.
# The prefix's share/ can be root-owned even when its bin/ is writable.
MAN_DIR="${TEETAP_MAN_DIR:-${BIN_DIR%/bin}/share/man/man1}"
if mkdir -p "$MAN_DIR" 2>/dev/null; then
    curl -fsSL "https://raw.githubusercontent.com/$REPO/$version/teetap.1" -o "$MAN_DIR/teetap.1" \
        || echo 'note: man page not installed (fetch failed)' >&2
else
    echo "note: man page not installed ($MAN_DIR is not writable)" >&2
fi

printf 'teetap %s installed to %s\n' "$version" "$BIN_DIR/teetap"

path_rank() { # position of $1 in PATH; empty when absent
    needle=$1
    rank=0
    saved_ifs=$IFS; IFS=:
    set -- $PATH
    IFS=$saved_ifs
    for p; do
        rank=$((rank + 1))
        if [ "$p" = "$needle" ]; then printf '%s\n' "$rank"; return; fi
    done
}

# Old copies in other candidate dirs are warned about, never deleted:
# a curl|sh script must not remove files it did not just create.
warn_strays() {
    new_rank=$(path_rank "$BIN_DIR")
    saved_ifs=$IFS; IFS=:
    set -- $CANDIDATES
    IFS=$saved_ifs
    for dir; do
        [ "$dir" = "$BIN_DIR" ] && continue
        [ -e "$dir/teetap" ] || continue
        stray_rank=$(path_rank "$dir")
        if [ -n "$stray_rank" ] && { [ -z "$new_rank" ] || [ "$stray_rank" -lt "$new_rank" ]; }; then
            printf 'warning: %s/teetap appears earlier on PATH and will shadow the copy just installed.\n' "$dir" >&2
        else
            printf 'note: an old copy remains at %s/teetap (shadowed by this install).\n' "$dir" >&2
        fi
        printf '  remove it: rm %s/teetap\n' "$dir" >&2
    done
}
warn_strays

if ! on_path "$BIN_DIR"; then
    printf 'note: %s is not on your PATH. Add it:\n' "$BIN_DIR" >&2
    case "${SHELL:-}" in
        */zsh)
            printf '  echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.zshrc && source ~/.zshrc\n' >&2 ;;
        *)
            printf '  echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.bashrc && source ~/.bashrc\n' >&2 ;;
    esac
fi
printf 'next (recommended): npx skills add https://github.com/%s --skill teetap\n' "$REPO"
printf 'next (no Node):     teetap skill install   # offline; --allow-fetch for the full structure\n'
