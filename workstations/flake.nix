{
  description = "Mikael's multi-platform Nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Darwin (macOS) support
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home-manager for user environment
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew integration for macOS
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew/main";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      ...
    }@inputs:
    let
      # User configuration - change this for different users
      username = "mikaelsiidorow";

      # Helper function to create a darwin system
      mkDarwinSystem =
        {
          system,
          hostname,
          extraModules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              username
              ;
          };
          modules = [
            # Host-specific configuration
            ./hosts/${hostname}

            # Homebrew integration
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                user = username;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
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
                  inherit inputs;
                  isDarwin = true;
                };
                users.${username} = import ./home;
              };
            }
          ] ++ extraModules;
        };

      # Helper function to create a NixOS system (for future use)
      mkNixosSystem =
        {
          system,
          hostname,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              inputs
              username
              ;
          };
          modules = [
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
                  inherit inputs;
                  isDarwin = false;
                };
                users.${username} = import ./home;
              };
            }
          ] ++ extraModules;
        };
    in
    {
      # Darwin (macOS) configurations
      darwinConfigurations = {
        "MacBook-Air" = mkDarwinSystem {
          system = "aarch64-darwin";
          hostname = "macbook-air";
        };
      };

      # NixOS configurations (uncomment when ready)
      # nixosConfigurations = {
      #   "nixos-laptop" = mkNixosSystem {
      #     system = "x86_64-linux";  # or "aarch64-linux" for ARM
      #     hostname = "nixos-laptop";
      #   };
      # };
    };
}
