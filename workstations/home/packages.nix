# Common packages - platform-agnostic
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Core utilities
    coreutils
    wget
    jq
    gettext

    # Version control
    git
    gh

    # Languages & runtimes
    python3
    fnm
    bun
    rustup

    # Package managers & tools
    uv

    # Nix tooling
    nixfmt-rfc-style

    # Databases
    postgresql_18
    pgadmin4-desktopmode
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
