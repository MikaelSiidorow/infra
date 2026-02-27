# Common packages - platform-agnostic
{
  pkgs,
  lib,
  inputs,
  isDarwin ? false,
  ...
}:
{
  programs.bat = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages =
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

      # Version control
      gh

      # Languages & runtimes
      python3
      fnm
      bun
      rustup

      # Package managers & tools
      uv

      # Nix tooling
      nixfmt-tree

      # Databases
      postgresql_18
      redis

      # Cloud
      google-cloud-sdk
      terraform

      # Media
      ffmpeg
      imagemagick

      # Document processing
      # Convert Markdown to PDF: pandoc input.md -o output.pdf --pdf-engine=typst
      pandoc
      typst
      poppler-utils

      # Development tools
      shellcheck
      shfmt
      mergiraf

      # Security
      _1password-cli
    ]
    # Platform-specific packages (NixOS/Linux only - macOS uses Homebrew)
    ++ lib.optionals (!isDarwin) [
      # AI tools
      inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
}
