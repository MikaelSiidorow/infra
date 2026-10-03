# Home-manager for the main user, with the shell environment shared with the
# workstations (modules/home/core).
{
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  programs.zsh.enable = true;
  users.users.${username}.shell = pkgs.zsh;
  # Lets zsh complete commands from system packages too.
  environment.pathsToLink = [ "/share/zsh" ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      isDarwin = false;
    };
    users.${username} = {
      imports = [ ../../../../modules/home/core ];
      home.stateVersion = "26.05";
    };
  };
}
