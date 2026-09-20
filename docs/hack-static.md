# Elisa presentation hosting

Public URL: https://elisa.hack.miksu.app/

Cloudflare manages DNS only (`proxied = false`). HTTPS terminates at the existing
Traefik ingress using Let's Encrypt. The site is served by non-root Nginx with a
read-only filesystem and content mount, no service-account token, dropped Linux
capabilities and no outbound network access. Ingress is restricted to Traefik.
Only static GET/HEAD requests are accepted; there is no public upload API.

## Upload

Prepare a directory containing **only public presentation files**, with the deck
named `index.html`. Copy its assets preserving their relative paths. Do not upload
the entire repository, recordings, datasets, credentials or private documents.

```bash
./bin/upload-hack-site.sh /absolute/path/to/public-presentation
```

This uses your existing SSH access to `root@89.167.124.71` (override with
`HACK_SSH_HOST`). Files live under `/var/lib/hack-static/releases/`; an atomic
`current` symlink selects the active version. Old releases remain on disk and are
not served by URL; keep them only as long as needed for rollback. Browser caching
is set to revalidate so updates appear on reload. Uploading does not rebuild the
container or require a Git commit.

Rollback: over SSH, point a temporary relative symlink at an existing
`releases/RELEASE` directory, then use `mv -Tf` to replace `current` atomically.

## Infrastructure handoff

The namespace, workload and DNS record were bootstrapped live for the deadline;
only a neutral placeholder was published. This PR makes them declarative. After
merge, ArgoCD adopts the workload and Terraform imports the existing DNS record
through `terraform/hack-import.tf`. No NixOS rebuild is required.

The host directory is specific to the current single Hetzner node, not replicated
storage. The upload script rejects symlinks and excludes `.git` and `.env*`, but
the caller must still prepare a public-only directory. No hosting setup guarantees
zero security risk; keep the pinned Nginx image updated.
