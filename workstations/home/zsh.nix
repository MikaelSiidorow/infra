# Zsh configuration - platform-agnostic
{
  lib,
  isDarwin ? false,
  ...
}:
{
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
        (''eval "$(fnm env --use-on-cd --shell zsh)"'')
        (''
          # Set up pnpm environment (not nix-like, but whatever for now)
          export PNPM_HOME="$HOME/.local/share/pnpm"
          mkdir -p "$PNPM_HOME"
          export PATH="$PNPM_HOME:$PATH"
          export PATH="$HOME/.local/bin:$PATH"
        '')
      ]
    );
  };
}
