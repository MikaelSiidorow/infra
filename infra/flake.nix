{
  description = "Infrastructure NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Home Assistant moves faster than the stable NixOS release.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dewclaw = {
      url = "github:MakiseKurisu/dewclaw";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      deploy-rs,
      dewclaw,
      disko,
      openwrt-imagebuilder,
      sops-nix,
      ...
    }:
    {
      apps.x86_64-linux = {
        deploy = deploy-rs.apps.x86_64-linux.default;
        cerberus-deploy = {
          type = "app";
          program = "${self.packages.x86_64-linux.cerberus-deploy}/bin/deploy-r6220";
          meta.description = "Deploy the Cerberus OpenWrt configuration";
        };
        hermes-deploy = {
          type = "app";
          program = "${self.packages.x86_64-linux.hermes-deploy}/bin/deploy-archer-c6-v2";
          meta.description = "Deploy the Hermes OpenWrt configuration";
        };
      };

      packages.x86_64-linux =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        in
        {
          cerberus-firmware = pkgs.callPackage ./openwrt/r6220/firmware.nix {
            inherit openwrt-imagebuilder;
          };
          cerberus-deploy = pkgs.callPackage dewclaw {
            configuration = ./openwrt/r6220/config.nix;
          };
          hermes-firmware = pkgs.callPackage ./openwrt/archer-c6-v2/firmware.nix {
            inherit openwrt-imagebuilder;
          };
          hermes-deploy = pkgs.callPackage dewclaw {
            configuration = ./openwrt/archer-c6-v2/config.nix;
          };
        };

      nixosConfigurations = {
        k8s-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./nixos/hosts/k8s-server/configuration.nix
          ];
        };

        hestia = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            username = "mikaelsiidorow";
          };
          modules = [
            disko.nixosModules.disko
            ./nixos/hosts/hestia/disk-config.nix
            ./nixos/hosts/hestia/hardware-configuration.nix
            ./nixos/hosts/hestia/default.nix
          ];
        };
      };

      deploy = {
        nodes = {
          k8s-server = {
            hostname = "89.167.124.71";
            sshUser = "root";
            profiles.system = {
              user = "root";
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.k8s-server;
            };
          };

          hestia = {
            hostname = "hestia.home.arpa";
            sshUser = "root";
            profiles.system = {
              user = "root";
              path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hestia;
            };
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
