{
  config,
  pkgs,
  isDarwin ? false,
  ...
}:
{
  home.packages = with pkgs; [
    age
    sops
  ];

  # rbw is only used to restore the sops age key on a new machine; see README
  # "SOPS age key restore". This writes config.json with an absolute pinentry
  # path, so credential prompts work without pinentry being on PATH.
  programs.rbw = {
    enable = true;
    settings = {
      email = "mikael+bitwarden@siidorow.com";
      base_url = "https://vault.bitwarden.eu";
      pinentry = if isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
    };
  };

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

    # Hugging Face read token, used by llm-pull to avoid anonymous rate limits.
    # Default symlink path under ~/.config/sops-nix/secrets; user-only on
    # purpose, so it is not readable from the shared model cache.
    secrets."hf/token".mode = "0400";
  };

  home.sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
}
