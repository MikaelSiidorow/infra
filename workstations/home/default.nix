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
    ./nix.nix
    ./direnv.nix
    ./git.nix
    ./github-auth.nix
    ./zsh.nix
    ./scripts.nix
    ./applications.nix
    ./nix-index.nix
    ./agents.nix
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
    # Firefox is not approved on the work (darwin) machine.
    ./firefox.nix
  ];

  home = {
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
