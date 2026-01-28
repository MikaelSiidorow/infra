# Desktop applications - platform-agnostic
{ pkgs, ... }:
{
  programs = {
    vscode = {
      enable = true;
    };
    firefox = {
      enable = true;
      package = pkgs.firefox;
    };
  };
}
