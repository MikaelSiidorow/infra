#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 1 || ! -d "$1" || ! -f "$1/index.html" ]]; then
  echo "Usage: $0 DIRECTORY (must contain index.html and only public assets)" >&2
  exit 1
fi
site_dir=$(cd -- "$1" && pwd)
if [[ -n $(find "$site_dir" -type l -print -quit) ]]; then
  echo "Upload folder must not contain symlinks; copy the public assets into it." >&2
  exit 1
fi
host=${HACK_SSH_HOST:-root@89.167.124.71}
release="$(date -u +%Y%m%dT%H%M%SZ)-${RANDOM}"
# Only deploy an explicitly prepared public folder, never the whole repository.
tar -C "$site_dir" --exclude='.git' --exclude='.env' --exclude='.env.*' -cf - . |
  ssh "$host" "set -eu
    umask 022
    mkdir -p /var/lib/hack-static/releases/$release
    tar --no-same-owner -xf - -C /var/lib/hack-static/releases/$release
    test -s /var/lib/hack-static/releases/$release/index.html
    chmod -R a+rX /var/lib/hack-static/releases/$release
    cd /var/lib/hack-static
    ln -s releases/$release .current-$release
    mv -Tf .current-$release current
    echo 'Published release $release'
  "
echo "https://elisa.hack.miksu.app/"
