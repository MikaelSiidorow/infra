{
  packageManagerPolicy,
  ...
}:
let
  inherit (packageManagerPolicy) cooldownSeconds;
in
{
  home.file.".bunfig.toml".text = ''
    [install]
    minimumReleaseAge = ${toString cooldownSeconds}
  '';
}
