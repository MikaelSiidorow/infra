# Common packages - platform-agnostic
{
  pkgs,
  pkgs-unstable,
  lib,
  inputs,
  isDarwin ? false,
  ...
}:
{
  programs = {
    bat.enable = true;

    gh = {
      enable = true;
      extensions = [ pkgs.gh-stack ];
      settings.aliases.co = "pr checkout";
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };

    ripgrep.enable = true;

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        format = lib.concatStrings [
          "$directory"
          "$git_branch"
          "$git_status"
          "$nix_shell"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];
        directory = {
          style = "bold blue";
          truncation_length = 3;
          truncate_to_repo = true;
        };
        git_branch.style = "bold purple";
        character = {
          success_symbol = "[>](bold green)";
          error_symbol = "[>](bold red)";
        };
        cmd_duration.min_time = 2000;
      };
    };
  };

  home = {
    # Global treefmt config — used as fallback when no repo-local treefmt.toml exists
    file.".config/treefmt/treefmt.toml".source = ./treefmt.toml;

    packages =
      with pkgs;
      [
        # Core utilities
        coreutils
        wget
        jq
        gettext
        fd
        btop
        tldr
        trash-cli

        # Languages & runtimes
        python3
        fnm
        bun
        rustup

        # Package managers & tools
        uv

        # Nix tooling
        nixfmt-tree

        # Formatting
        oxfmt

        # Databases
        postgresql_18
        redis
        sqlite

        # Cloud
        azure-cli
        terraform

        # Media
        ffmpeg
        imagemagick

        # Document processing
        # Convert Markdown to PDF: pandoc input.md -o output.pdf --pdf-engine=typst
        pandoc
        typst
        poppler-utils
        typstyle

        # Development tools
        shellcheck
        shfmt
        mergiraf

        # Security
        _1password-cli

        # AI tools
        inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ]
      # Platform-specific packages (NixOS/Linux only - macOS uses Homebrew)
      ++ lib.optionals (!isDarwin) [
        inputs.opencode-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ]
      # Platform-specific packages (macOS only)
      ++ lib.optionals isDarwin [
        google-cloud-sdk

        # Cursor CLI (not in claude-code-nix-style flake; from unstable)
        pkgs-unstable.cursor-cli
      ];
  };
}
