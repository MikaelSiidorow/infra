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

# 3. Clone and activate.
git clone https://github.com/MikaelSiidorow/nix-config.git ~/nix-config
cd ~/nix-config
make switch
```

If you need a different hostname, add it to `darwinHosts` (top of `flake.nix`) before switching.

Optional: append `extra-substituters = https://cache.flakehub.com` to `/etc/nix/nix.custom.conf` if you want the FlakeHub cache actually queried (Determinate marks it trusted but doesn't query it). Leave the `access-tokens` line alone.

### Linux (Pop!\_OS)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

git clone https://github.com/MikaelSiidorow/nix-config.git ~/nix-config
cd ~/nix-config

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

## Migration checklist

Not managed by the flake (bring over manually):

- `~/.ssh/` for GitHub pushes
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
