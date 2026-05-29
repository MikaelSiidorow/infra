# Multi-host Nix configuration Makefile
# Supports nix-darwin (macOS) and home-manager (Linux standalone)

# Detect platform
HOSTNAME := $(shell hostname -s)
UNAME := $(shell uname -s)

# darwin-rebuild auto-resolves darwinConfigurations.$(scutil --get LocalHostName)
# when no flake attr is specified, so we pass `.` and let it pick.
# home-manager has no equivalent default, so we pass the full target.
ifeq ($(UNAME),Darwin)
	BUILD_CMD := darwin-rebuild
	NEEDS_SUDO := sudo
	FLAKE_TARGET := .
	DISPLAY_TARGET := darwinConfigurations.$(HOSTNAME)
else
	BUILD_CMD := home-manager
	NEEDS_SUDO :=
	FLAKE_TARGET := .#mikaelsiidorow@pop-os
	DISPLAY_TARGET := $(FLAKE_TARGET)
endif

# Default target - show help
.PHONY: help
help:
	@echo "Nix Configuration Management"
	@echo ""
	@echo "Detected: $(HOSTNAME) ($(UNAME))"
	@echo "Target: $(DISPLAY_TARGET)"
	@echo ""
	@echo "Common targets:"
	@echo "  make switch       - Build and activate configuration for current host"
	@echo "  make build        - Build configuration without activating"
	@echo "  make check        - Check flake for errors"
	@echo "  make update       - Update flake inputs"
	@echo "  make upgrade      - Update inputs and switch"
	@echo "  make clean        - Run garbage collection"
	@echo "  make fmt          - Format all .nix files"
	@echo ""
	@echo "Other targets:"
	@echo "  make popos        - Build and activate Pop!_OS configuration"
	@echo "  make diff         - Show what would change"
	@echo "  make history      - Show system generations"
	@echo "  make rollback     - Rollback to previous generation"

# Auto-detected switch
.PHONY: switch
switch:
	@echo "Building $(DISPLAY_TARGET)..."
	$(NEEDS_SUDO) $(BUILD_CMD) switch --flake $(FLAKE_TARGET)

# Build without activating
.PHONY: build
build:
	@echo "Building $(DISPLAY_TARGET)..."
	$(NEEDS_SUDO) $(BUILD_CMD) build --flake $(FLAKE_TARGET)

# Check flake for errors
.PHONY: check
check:
	nix flake check

# Show what would change (dry-run)
.PHONY: diff
diff:
	@echo "Checking changes for $(DISPLAY_TARGET)..."
ifeq ($(BUILD_CMD),darwin-rebuild)
	$(NEEDS_SUDO) darwin-rebuild build --flake $(FLAKE_TARGET)
	nix store diff-closures /run/current-system ./result
else
	home-manager build --flake $(FLAKE_TARGET)
	nix store diff-closures ~/.local/state/nix/profiles/home-manager ./result
endif

# Update flake inputs
.PHONY: update
update:
	nix flake update

# Update and switch
.PHONY: upgrade
upgrade: update switch

# Garbage collection
.PHONY: clean
clean:
	nix-collect-garbage -d

# Aggressive cleanup (30 day old generations)
.PHONY: deep-clean
deep-clean:
	nix-collect-garbage --delete-older-than 30d
	@echo "Optimizing nix store..."
	nix store optimise

# Format all nix files
.PHONY: fmt
fmt:
	@echo "Formatting nix files..."
	nix fmt

# Host-specific overrides (use when not running on the target host)
.PHONY: popos
popos:
	home-manager switch --flake .#mikaelsiidorow@pop-os

# Show system generations
.PHONY: history
history:
ifeq ($(BUILD_CMD),darwin-rebuild)
	sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
else
	home-manager generations
endif

# Rollback to previous generation
.PHONY: rollback
rollback:
ifeq ($(BUILD_CMD),darwin-rebuild)
	sudo darwin-rebuild rollback
else
	home-manager generations | head -2 | tail -1 | awk '{print $$7}' | xargs home-manager switch --generation
endif

# Verify flake inputs are up to date
.PHONY: check-updates
check-updates:
	nix flake metadata
	@echo ""
	@echo "Run 'make update' to update all inputs"

# Show flake info
.PHONY: info
info:
	nix flake show

# Test build without switching (useful for CI/testing)
.PHONY: test
test: check build
