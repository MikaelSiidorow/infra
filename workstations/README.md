# Nix Configuration

[![CI](https://github.com/MikaelSiidorow/nix-config/actions/workflows/ci.yml/badge.svg)](https://github.com/MikaelSiidorow/nix-config/actions/workflows/ci.yml)

Multi-platform Nix configuration supporting macOS (nix-darwin) and Linux (home-manager standalone).

Configured hosts:

| Attr                    | Platform       | Notes                   |
| ----------------------- | -------------- | ----------------------- |
| `MacBook-Air`           | aarch64-darwin | nix-darwin              |
| `MacBook-Pro`           | aarch64-darwin | nix-darwin              |
| `mikaelsiidorow@pop-os` | x86_64-linux   | home-manager standalone |

## Quick Start

### macOS (fresh machine)

The flake assumes Determinate Nix (`nix.enable = false`), so the upstream installer will not work.

```bash
# 1. Install Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Set LocalHostName to match a darwinConfigurations attr.
#    darwin-rebuild reads scutil --get LocalHostName as the default target.
sudo scutil --set HostName MacBook-Pro
sudo scutil --set LocalHostName MacBook-Pro
sudo scutil --set ComputerName MacBook-Pro

# 3. Clone.
git clone https://github.com/MikaelSiidorow/nix-config.git ~/nix-config
cd ~/nix-config

# 4. Restore the SOPS age key using the commands below.

# 5. Bootstrap nix-darwin. After this, `make switch` is available.
nix run github:LnL7/nix-darwin/master#darwin-rebuild -- switch --flake .
```

If you need a different hostname, add it to `darwinHosts` (top of `flake.nix`) before switching.

Optional: append `extra-substituters = https://cache.flakehub.com` to `/etc/nix/nix.custom.conf` if you want the FlakeHub cache actually queried (Determinate marks it trusted but doesn't query it). Leave the `access-tokens` line alone.

### SOPS age key restore

Restore the SOPS age key before the first switch on every machine. This key is intentionally not managed by Nix; it is the recovery key that unlocks encrypted repo secrets. `home-manager build` can evaluate without it, but activation needs it when `sops-nix` starts decrypting secrets.

```bash
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops ~/.config/sops/age

# Only needed the first time rbw is configured on this machine:
nix shell nixpkgs#rbw -c rbw config set base_url "https://vault.bitwarden.eu"
nix shell nixpkgs#rbw -c rbw config set email "<bitwarden-account-email>"
nix shell nixpkgs#rbw -c rbw register  # first rbw device login may require Bitwarden API keys
nix shell nixpkgs#rbw -c rbw login

# Needed whenever rbw is locked or stale:
nix shell nixpkgs#rbw -c rbw unlock
nix shell nixpkgs#rbw -c rbw sync

# Restore the age private key without printing it.
( umask 077
  nix shell nixpkgs#rbw -c rbw get "sops age key" \
    | awk '/^AGE-SECRET-KEY-/ { print; found=1 } END { if (!found) exit 1 }' \
    > ~/.config/sops/age/keys.txt
)

# Optional sanity check: prints only the public age recipient.
nix shell nixpkgs#age -c age-keygen -y ~/.config/sops/age/keys.txt
```

### Linux (Pop!\_OS)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

git clone https://github.com/MikaelSiidorow/nix-config.git ~/nix-config
cd ~/nix-config

# Restore the SOPS age key using the commands above before activating.
```

Activate Home Manager:

```bash
# Bootstrap (uses latest home-manager from master, may differ from flake.lock)
nix run home-manager/master -- switch --flake .#mikaelsiidorow@pop-os -b backup

# Subsequent updates
make switch
```

## Common Commands

```bash
make switch       # Build and activate
make diff         # Preview changes
make update       # Update inputs
make upgrade      # Update + switch
make check        # Validate flake
make fmt          # Format code
```

On macOS `make switch` passes `--flake .` and lets `darwin-rebuild` resolve to `darwinConfigurations.$(hostname -s)`. Run `make help` for the full list.

## Secrets

Secrets use `sops-nix` with a single personal age recipient. The age private key lives at `~/.config/sops/age/keys.txt` on each machine and is backed up in Bitwarden as `sops age key`.

Current managed secret:

- `ssh/git_signing_key` -> `~/.ssh/git_signing_key`, used for SSH commit and tag signing.

Git signing is declarative in `home/git.nix` and uses `mikael@siidorow.com`. The public key is written to `~/.ssh/git_signing_key.pub`; add it to GitHub as an SSH **Signing key** if it is not already present:

```bash
gh ssh-key add ~/.ssh/git_signing_key.pub --type signing --title "Pop!_OS git signing"
```

The GitHub signing key is account-level, so a new machine that decrypts the same signing key does not need a second GitHub registration.

## Migration checklist

Not managed by the flake (bring over manually):

- SSH authentication keys for GitHub pushes. The SSH signing key is managed by sops-nix.
- App logins: Slack, Teams, browser, `gh auth login`
- Browser data via sign-in (Firefox Sync, Chrome sync); extensions are nix-managed
- VS Code settings via account sync; the binary is nix-managed
- Mutable `~/.claude/` state: `settings.json`, memories, history, plugins. `CLAUDE.md` and `statusline-command.sh` are home-managed.

## Structure

```
├── flake.nix              # Hosts, overlays, system constructors
├── Makefile               # Build commands (OS-detected)
├── hosts/                 # Per-host modules (Linux only; darwin lives in flake.nix)
├── modules/{common,darwin,nixos}/
├── home/                  # User environment (home-manager)
│   ├── claude-code/       # CLAUDE.md + statusline
│   └── ...
└── pkgs/                  # Custom packages (mergiraf with PO grammar)
```

## Troubleshooting

**Nix daemon not found:**

```bash
. '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
```

**OpenGL issues on Linux:** GUI apps use nixGL wrappers automatically. See `home/applications-linux.nix`.

## License

MIT
