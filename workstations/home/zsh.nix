# Zsh configuration - platform-agnostic
{
  lib,
  isDarwin ? false,
  ...
}:
{
  home.sessionVariables = {
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };

  home.sessionPath = [
    "$HOME/.local/share/pnpm"
    "$HOME/.local/bin"
  ];

  home.activation.createPnpmHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/share/pnpm"
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
      ];
      theme = "agnoster";
    };

    initContent = lib.mkMerge (
      # Darwin-specific nix-daemon setup
      (lib.optionals isDarwin [
        (lib.mkBefore ''
          if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi
        '')
      ])
      ++ [
        ''eval "$(fnm env --use-on-cd --shell zsh)"''
      ]
    );
  };
}
