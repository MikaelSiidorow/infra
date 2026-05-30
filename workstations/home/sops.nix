{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    age
    rbw
    sops
  ];

  sops = {
    age = {
      keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      sshKeyPaths = [ ];
    };

    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets."ssh/git_signing_key" = {
      path = "${config.home.homeDirectory}/.ssh/git_signing_key";
      mode = "0600";
    };
  };

  home.sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
}
