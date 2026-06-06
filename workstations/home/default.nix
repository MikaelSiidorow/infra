# Home-manager configuration entry point
{
  lib,
  inputs,
  isDarwin ? false,
  ...
}:
{
  imports = [
    ./packages.nix
    ./direnv.nix
    ./git.nix
    ./zsh.nix
    ./scripts.nix
    ./applications.nix
    ./nix-index.nix
    ./firefox.nix
    ./claude-code.nix
    ./zed.nix
    ./package-managers
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-index-database.homeModules.nix-index
    ./sops.nix
  ]
  ++ lib.optionals isDarwin [
    ./skhd.nix
  ]
  ++ lib.optionals (!isDarwin) [
    ./applications-linux.nix
    ./gnome.nix
  ];

  home = {
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
