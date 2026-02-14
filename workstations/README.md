# Nix Configuration

[![CI](https://github.com/MikaelSiidorow/nix-config/actions/workflows/ci.yml/badge.svg)](https://github.com/MikaelSiidorow/nix-config/actions/workflows/ci.yml)

Multi-platform Nix configuration supporting macOS (nix-darwin) and Linux (home-manager standalone).

## Quick Start

### macOS

```bash
git clone https://github.com/MikaelSiidorow/nix-config.git ~/nix-config
cd ~/nix-config
make switch
```

### Linux (Pop!_OS)

```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Clone and activate
git clone https://github.com/MikaelSiidorow/nix-config.git ~/nix-config
cd ~/nix-config

# Initial bootstrap (uses latest home-manager from master branch)
# Note: This may differ from the version pinned in flake.lock
nix run home-manager/master -- switch --flake .#mikaelsiidorow@pop-os -b backup

# Future updates (uses pinned version from flake.lock)
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

Run `make help` for all commands.

## Structure

```
├── flake.nix              # Main configuration
├── Makefile               # Build commands
├── hosts/
│   ├── macbook-air/       # macOS host
│   └── pop-os/            # Pop!_OS host
└── home/                  # Shared user config
    ├── packages.nix       # CLI tools
    ├── git.nix
    ├── zsh.nix
    ├── gnome.nix          # GNOME settings (Linux)
    └── skhd.nix           # Window manager (macOS)
```

## Troubleshooting

**Nix daemon not found:**
```bash
. '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
```

**OpenGL issues on Linux:**
GUI apps use nixGL wrappers automatically. See `home/applications-linux.nix`.

## License

MIT
