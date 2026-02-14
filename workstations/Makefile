# Multi-host Nix configuration Makefile
# Supports nix-darwin (macOS) and home-manager (Linux standalone)

# Detect current host
HOSTNAME := $(shell hostname)
UNAME := $(shell uname -s)

# Map hostnames to flake configurations
ifeq ($(HOSTNAME),MacBook-Air)
	FLAKE_TARGET := MacBook-Air
	BUILD_CMD := darwin-rebuild
	NEEDS_SUDO := sudo
else ifeq ($(HOSTNAME),pop-os)
	FLAKE_TARGET := mikaelsiidorow@pop-os
	BUILD_CMD := home-manager
	NEEDS_SUDO :=
else
	# Fallback: try to detect by OS
	ifeq ($(UNAME),Darwin)
		FLAKE_TARGET := MacBook-Air
		BUILD_CMD := darwin-rebuild
		NEEDS_SUDO := sudo
	else
		FLAKE_TARGET := mikaelsiidorow@pop-os
		BUILD_CMD := home-manager
		NEEDS_SUDO :=
	endif
endif

# Default target - show help
.PHONY: help
help:
	@echo "Nix Configuration Management"
	@echo ""
	@echo "Detected: $(HOSTNAME) ($(UNAME))"
	@echo "Target: $(FLAKE_TARGET)"
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
	@echo "Host-specific targets:"
	@echo "  make mac          - Build and activate macOS configuration"
	@echo "  make popos        - Build and activate Pop!_OS configuration"
	@echo ""
	@echo "Other targets:"
	@echo "  make diff         - Show what would change"
	@echo "  make history      - Show system generations"
	@echo "  make rollback     - Rollback to previous generation"

# Auto-detected switch
.PHONY: switch
switch:
	@echo "Building configuration for $(FLAKE_TARGET)..."
	$(NEEDS_SUDO) $(BUILD_CMD) switch --flake .#$(FLAKE_TARGET)

# Build without activating
.PHONY: build
build:
	@echo "Building configuration for $(FLAKE_TARGET)..."
	$(NEEDS_SUDO) $(BUILD_CMD) build --flake .#$(FLAKE_TARGET)

# Check flake for errors
.PHONY: check
check:
	nix flake check

# Show what would change (dry-run)
.PHONY: diff
diff:
	@echo "Checking changes for $(FLAKE_TARGET)..."
ifeq ($(BUILD_CMD),darwin-rebuild)
	$(NEEDS_SUDO) darwin-rebuild build --flake .#$(FLAKE_TARGET)
	nix store diff-closures /run/current-system ./result
else
	home-manager build --flake .#$(FLAKE_TARGET)
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

# Host-specific targets
.PHONY: mac
mac:
	sudo darwin-rebuild switch --flake .#MacBook-Air

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
