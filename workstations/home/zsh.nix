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

    shellAliases = {
      p = "pnpm";
      tf = "terraform";
      bb = "bun --bun";
      treefmt = "treefmt --config-file ~/.config/treefmt/treefmt.toml --allow-missing-formatter";

      # Safety
      rm = "rm -i";
      tp = "trash-put";

      # Claude
      c = "claude";
      cco = "claude --continue";
      cres = "claude --resume";
      crew = "claude /review";
      cwt = "claude-worktree";
    };

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
      # Linux-specific: clear env vars inherited from nixGL/wrapGAppsHook terminal wrapper.
      # These are only needed by the terminal emulator itself (for GPU rendering and GTK),
      # not by child processes — system apps need the system's own drivers and GIO modules.
      ++ (lib.optionals (!isDarwin) [
        (lib.mkBefore ''
          unset LD_LIBRARY_PATH
          unset LIBGL_DRIVERS_PATH
          unset LIBVA_DRIVERS_PATH
          unset __EGL_VENDOR_LIBRARY_FILENAMES
          unset GBM_BACKENDS_PATH
          unset VK_ICD_FILENAMES
          unset GIO_EXTRA_MODULES
        '')
      ])
      ++ [
        ''
          # GPG TTY for signing
          export GPG_TTY=$(tty)

          # Hide user@host in agnoster prompt for local sessions
          export DEFAULT_USER=$(whoami)

          # fnm (Fast Node Manager) integration
          eval "$(fnm env --use-on-cd --shell zsh)"
        ''
      ]
    );
  };
}
