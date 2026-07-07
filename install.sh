#!/bin/sh
# teetap installer: downloads the pinned release script to ~/.local/bin.
#   curl -fsSL https://raw.githubusercontent.com/OWNER/teetap/main/install.sh | sh
#   TEETAP_VERSION=v0.1.0 sh install.sh   # pin a specific release
set -eu

REPO="${TEETAP_REPO:-weefaa/teetap}"
BIN_DIR="${TEETAP_BIN_DIR:-$HOME/.local/bin}"

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
MAN_DIR="${TEETAP_MAN_DIR:-${BIN_DIR%/bin}/share/man/man1}"
mkdir -p "$MAN_DIR"
curl -fsSL "https://raw.githubusercontent.com/$REPO/$version/teetap.1" -o "$MAN_DIR/teetap.1" \
    || echo 'note: man page not installed (fetch failed)' >&2

printf 'teetap %s installed to %s\n' "$version" "$BIN_DIR/teetap"
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        printf 'note: %s is not on your PATH. Add it:\n' "$BIN_DIR" >&2
        case "${SHELL:-}" in
            */zsh)
                printf '  echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.zshrc && source ~/.zshrc\n' >&2 ;;
            *)
                printf '  echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.bashrc && source ~/.bashrc\n' >&2 ;;
        esac
        ;;
esac
printf 'next (recommended): npx skills add https://github.com/%s --skill teetap\n' "$REPO"
printf 'next (no Node):     teetap skill install   # offline; --allow-fetch for the full structure\n'
