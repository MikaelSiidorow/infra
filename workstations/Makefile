.PHONY: update
update:
	nix run nix-darwin/master#darwin-rebuild -- switch --flake .

.PHONY: clean
clean:
	nix-collect-garbage -d