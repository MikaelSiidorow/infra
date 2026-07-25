{ inputs, ... }:
{
  imports = [ inputs.aeye.homeManagerModules.default ];

  services.aeye.enable = true;
}
