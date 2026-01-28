# Common packages - platform-agnostic
{ pkgs, ... }:
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

  home.packages = with pkgs; [
    # Core utilities
    coreutils
    wget
    jq
    gettext

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
    nixfmt

    # Databases
    postgresql_18
    redis

    # Cloud
    google-cloud-sdk

    # Media
    ffmpeg
    imagemagick

    # Document processing
    # Convert Markdown to PDF: pandoc input.md -o output.pdf --pdf-engine=typst
    pandoc
    typst

    # Development tools
    shellcheck
    mergiraf

    # Security
    _1password-cli
  ];
}
