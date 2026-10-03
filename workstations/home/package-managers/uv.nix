{
  packageManagerPolicy,
  ...
}:
let
  inherit (packageManagerPolicy) cooldownDuration;
in
{
  xdg.configFile."uv/uv.toml".text = ''
    exclude-newer = "${cooldownDuration}"

    [pip]
    exclude-newer = "${cooldownDuration}"
  '';
}
