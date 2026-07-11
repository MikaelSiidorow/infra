{
  description = "Mikael's multi-platform Nix configuration";

  inputs = {
    # Default package set: stable release branch for broad desktop/system use.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Fast lane for browsers and selected fast-moving desktop apps.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Darwin (macOS) support
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home-manager for user environment
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative secret management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Prebuilt nix-index database and comma command lookup
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenGL wrapper for non-NixOS Linux
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew integration for macOS. Taps are pinned for reproducibility;
    # homebrew-cask is patched in mkDarwinSystem (see patchedHomebrewCask).
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew/main";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-cmux = {
      url = "github:manaflow-ai/homebrew-cmux";
      flake = false;
    };

    # Nix User Repository (Firefox extensions, etc.)
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code with automatic updates
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Codex CLI with automatic updates
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenCode with automatic updates (for NixOS/Linux)
    opencode-nix = {
      url = "github:dan-online/opencode-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nix-darwin,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-cmux,
      claude-code-nix,
      codex-cli-nix,
      opencode-nix,
      nur,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      # NixOS / Linux home-manager (pop-os) account.
      username = "mikaelsiidorow";
      # macOS account (different local username).
      darwinUsername = "mikael";

      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      mkApp = program: description: {
        type = "app";
        inherit program;
        meta.description = description;
      };

      mkPkgsUnstable =
        system:
        import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

      # Custom mergiraf with tree-sitter-po grammar for PO/gettext merge support
      mergirafOverlay = final: prev: {
        mergiraf = final.callPackage ./pkgs/mergiraf-custom { };
      };

      # Skip direnv's checkPhase on darwin. Its test suite forks subshells
      # that hang inside nix's macOS sandbox, and aarch64-darwin binary
      # caches often lag behind, forcing source builds that deadlock.
      direnvOverlay = final: prev: {
        direnv = prev.direnv.overrideAttrs (_: {
          doCheck = false;
        });
      };

      # Darwin hosts: attr key is the LocalHostName (must match
      # `scutil --get LocalHostName`, which is what darwin-rebuild uses
      # to resolve the default flake target).
      darwinHosts = {
        "mikael-mbp-2026" = "aarch64-darwin";
      };

      # Helper function to create a darwin system
      mkDarwinSystem =
        {
          system,
          username,
          hostname ? null,
          extraModules ? [ ],
        }:
        let
          pkgs-unstable = mkPkgsUnstable system;

          # Offline tap parsing treats `depends_on macos: :sym` as an exact
          # match, rejecting newer macOS (e.g. orbstack on Tahoe). Rewrite bare
          # symbols to ">= :sym" to match Homebrew's API behaviour. Existing
          # comparators and arrays are left alone (regex matches only `: :sym`).
          patchedHomebrewCask = pkgs-unstable.runCommand "homebrew-cask-patched" { } ''
            cp -r ${homebrew-cask} $out
            chmod -R u+w $out
            find $out/Casks -name '*.rb' -print0 \
              | xargs -0 sed -i -E 's/depends_on macos: (:[a-z_]+)/depends_on macos: ">= \1"/'
          '';
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              pkgs-unstable
              username
              ;
          };
          modules = [
            # Custom package overlays
            {
              nixpkgs.overlays = [
                mergirafOverlay
                direnvOverlay
                nur.overlays.default
              ];
            }

            # Common darwin host wiring (was hosts/macbook-air/default.nix)
            {
              imports = [ ./modules/darwin ];
              nixpkgs.hostPlatform = system;
              system.primaryUser = username;
              users.users.${username}.home = "/Users/${username}";
            }

            # Homebrew integration
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                user = username;
                # homebrew-core pin is what enables offline mode; cask is patched.
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = patchedHomebrewCask;
                  "manaflow-ai/homebrew-cmux" = homebrew-cmux;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }

            # Home-manager integration
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs pkgs-unstable hostname;
                  isDarwin = true;
                };
                users.${username} = import ./home;
              };
            }
          ]
          ++ extraModules;
        };

      # Helper function to create a NixOS system (for future use)
      mkNixosSystem =
        {
          system,
          hostname,
          extraModules ? [ ],
        }:
        let
          pkgs-unstable = mkPkgsUnstable system;
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              pkgs-unstable
              username
              ;
          };
          modules = [
            # Custom package overlays
            {
              nixpkgs.overlays = [
                mergirafOverlay
                nur.overlays.default
              ];
            }

            # Host-specific configuration
            ./hosts/${hostname}

            # Home-manager integration
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs pkgs-unstable hostname;
                  isDarwin = false;
                };
                users.${username} = import ./home;
              };
            }
          ]
          ++ extraModules;
        };

      # Helper function to create a home-manager standalone config
      mkHomeConfig =
        {
          system,
          hostname,
          extraModules ? [ ],
        }:
        let
          pkgs-unstable = mkPkgsUnstable system;
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              nur.overlays.default
            ];
          };
          extraSpecialArgs = {
            inherit
              self
              inputs
              pkgs-unstable
              hostname
              ;
            isDarwin = false;
          };
          modules = [
            ./hosts/${hostname}
            ./home
            {
              home = {
                inherit username;
                homeDirectory = "/home/${username}";
              };
            }
          ]
          ++ extraModules;
        };
    in
    {
      # Darwin (macOS) configurations
      darwinConfigurations = builtins.mapAttrs (
        hostname: system:
        mkDarwinSystem {
          inherit system hostname;
          username = darwinUsername;
        }
      ) darwinHosts;

      # Standalone package for testing: nix build .#packages.aarch64-darwin.mergiraf
      packages = builtins.listToAttrs (
        map (system: {
          name = system;
          value = {
            mergiraf =
              let
                pkgs = import nixpkgs { inherit system; };
              in
              pkgs.callPackage ./pkgs/mergiraf-custom { };
          };
        }) supportedSystems
      );

      apps = builtins.listToAttrs (
        map (system: {
          name = system;
          value = {
            home-manager = mkApp "${home-manager.packages.${system}.home-manager}/bin/home-manager" "Run the locked Home Manager CLI";
          }
          // lib.optionalAttrs (lib.hasSuffix "darwin" system) {
            darwin-rebuild = mkApp "${nix-darwin.packages.${system}.darwin-rebuild}/bin/darwin-rebuild" "Run the locked nix-darwin rebuild CLI";
          };
        }) supportedSystems
      );

      # NixOS configurations (uncomment when ready)
      # nixosConfigurations = {
      #   "nixos-laptop" = mkNixosSystem {
      #     system = "x86_64-linux";  # or "aarch64-linux" for ARM
      #     hostname = "nixos-laptop";
      #   };
      # };

      # Home-manager standalone configurations (for non-NixOS systems)
      homeConfigurations = {
        "mikaelsiidorow@pop-os" = mkHomeConfig {
          system = "x86_64-linux";
          hostname = "pop-os";
        };
      };

      # Formatter configuration for `nix fmt`
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      };
    };
}
