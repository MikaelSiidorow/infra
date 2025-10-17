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
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
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
            stateVersion = "25.05";
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
            pgadmin4-desktopmode

            bun

            redis

            rustup
            imagemagick
            _1password-cli
          ];

          xdg.configFile."skhd/skhdrc" = {
            text = ''
              # -- App Switching Hotkeys --
              # Switches to an application, opening it if it's not already running.

              ctrl + cmd - 1 : open -a "Ghostty"
              ctrl + cmd - 2 : open -a "Visual Studio Code"
              ctrl + cmd - 3 : open -a "Google Chrome"
              ctrl + cmd - 4 : open -a "Slack"

            '';
          };

          programs = {
            git = {
              enable = true;
              ignores = [
                ".DS_STORE"
                "CLAUDE.md"
                ".claude"
                ".github/copilot-instructions.md"
                "todo.md"
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

              initContent = lib.mkMerge [
                (lib.mkBefore ''
                  if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
                    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                    . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
                  fi
                '')
                (''eval "$(fnm env --use-on-cd --shell zsh)"'')
                (''
                  # Set up pnpm environment (not nix-like, but whatever for now)
                  export PNPM_HOME="$HOME/.local/share/pnpm"
                  mkdir -p "$PNPM_HOME"
                  export PATH="$PNPM_HOME:$PATH"
                '')
              ];
            };
            vscode = {
              enable = true;
            };
            firefox = {
              enable = true;
            };
          };

        };
    in
    {
      darwinConfigurations."MacBook-Air" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [
                pkgs.vim
              ];

              services.skhd.enable = true;

              nix.settings.experimental-features = "nix-command flakes";

              nixpkgs = {
                config = {
                  allowUnfree = true;
                };
                hostPlatform = system;
              };

              programs.zsh.enable = true;

              system.configurationRevision = self.rev or self.dirtyRev or null;

              time.timeZone = "Europe/Helsinki";

              system.defaults = {
                NSGlobalDomain.AppleICUForce24HourTime = true;
                menuExtraClock.ShowSeconds = true;
                dock = {
                  launchanim = false;
                  tilesize = 48;
                  autohide = true;
                  show-recents = false;
                  orientation = "bottom";
                  persistent-apps = [
                    {
                      app = "/System/Library/CoreServices/Finder.app";
                    }
                    {
                      app = "/System/Applications/Notes.app";
                    }
                    {
                      app = "/System/Applications/System Settings.app";
                    }
                    {
                      app = "/Applications/Slack.app";
                    }
                    {
                      app = "/Applications/1Password.app";
                    }
                    {
                      app = "/Applications/Google Chrome.app";
                    }
                    {
                      app = "/Applications/Ghostty.app";
                    }
                    {
                      app = "${pkgs.vscode}/Applications/Visual Studio Code.app";
                    }
                  ];
                  persistent-others = [
                    "/Users/mikaelsiidorow/Downloads"
                  ];
                };
              };
              system.stateVersion = 6;
              system.primaryUser = "mikaelsiidorow";

              nix.enable = false;

              users.users.mikaelsiidorow.home = "/Users/mikaelsiidorow";

              security.pam.services.sudo_local.touchIdAuth = true;

              homebrew = {
                enable = true;

                onActivation = {
                  autoUpdate = true;
                  # cleanup = "zap";
                  upgrade = true;
                };

                global = {
                  brewfile = true;
                };

                brews = [
                  "cloudflared"
                ];

                casks = [
                  "orbstack"
                  "ghostty"
                  "google-chrome"
                  "1password"
                  "amethyst"
                  "alfred"
                  "slack"
                  "microsoft-auto-update" # needed for teams I guess?
                  "microsoft-teams"
                  "drata-agent"
                  "ngrok"
                ];
              };
            }
          )
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "mikaelsiidorow";

              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = false;

              autoMigrate = true;
            };
          }

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
