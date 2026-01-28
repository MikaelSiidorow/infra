# Default target for macOS
.PHONY: switch
switch:
	sudo darwin-rebuild switch --flake .#MacBook-Air

# Alias for backwards compatibility
.PHONY: update
update: switch

.PHONY: clean
clean:
	nix-collect-garbage -d

.PHONY: upgrade
upgrade:
	nix flake update
