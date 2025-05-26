.PHONY: update
update:
	sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .

.PHONY: clean
clean:
	nix-collect-garbage -d

.PHONY: upgrade
upgrade:
	nix flake update
