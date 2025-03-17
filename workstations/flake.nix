{
  description = "Example nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      homeManagerConfig =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          home = {
            stateVersion = "24.11";
            username = "mikaelsiidorow";
          };

          programs.home-manager.enable = true;

          home.packages = with pkgs; [
            coreutils
            wget

            python3
            fnm
            uv
            nixfmt-rfc-style
            git
            gh
            jq

            postgresql_15
            cloudflared

            _1password-cli
          ];

          programs = {
            git = {
              enable = true;
              ignores = [
                ".DS_STORE"
              ];
              userName = "Mikael Siidorow";
              userEmail = "mikael.siidorow@teamspective.com";
              extraConfig = {
                init.defaultBranch = "main";
                core = {
                  autocrlf = "input";
                };
                branch.sort = "-committerdate";
                merge.conflictstyle = "zdiff3";
                pull.ff = "only";
                rebase.autoStash = true;
                rerere.enabled = true;
              };
            };
            zsh = {
              enable = true;
              enableCompletion = true;
              autosuggestion.enable = true;
              syntaxHighlighting.enable = true;

              oh-my-zsh = {
                enable = true;
                plugins = [
                  "git"
                  "docker"
                ];
                theme = "agnoster";
              };

              initExtraFirst = ''
                if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
                  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                  . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
                fi
              '';

              initExtra = ''
                eval "$(fnm env --use-on-cd --shell zsh)"
              '';
            };
            vscode = {
              enable = true;
            };
          };

        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Mikaels-MacBook-Air
      darwinConfigurations."Mikaels-MacBook-Air" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [
                pkgs.vim
              ];

              nix.settings.experimental-features = "nix-command flakes";

              nixpkgs = {
                config = {
                  allowUnfree = true;
                };
                hostPlatform = system;
              };

              programs.zsh.enable = true;

              system.configurationRevision = self.rev or self.dirtyRev or null;

              system.stateVersion = 6;

              nix.enable = false;

              users.users.mikaelsiidorow.home = "/Users/mikaelsiidorow";

              security.pam.services.sudo_local.touchIdAuth = true;

              homebrew = {
                enable = true;
                casks = [
                  "orbstack"
                  "ghostty"
                  "google-chrome"
                  "1password"
                  "amethyst"
                  "alfred"
                  "slack"
                  "drata-agent"
                ];
              };
            }
          )

          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
              users.mikaelsiidorow = homeManagerConfig;
            };
          }
        ];
      };
    };
}
