# GitHub API auth: raises the 60 req/hr unauthenticated cap to 5000. A
# read-only / no-scope PAT in sops (github.token) suffices.
{ config, ... }:
{
  sops.secrets."github/token" = {
    mode = "0600";
  };

  # Templated (not inline) so the token stays out of the store; `!include` is
  # optional, so nix won't error before the secret is decrypted.
  sops.templates."nix-access-tokens.conf".content = ''
    access-tokens = github.com=${config.sops.placeholder."github/token"}
  '';

  xdg.configFile."nix/nix.conf".text = ''
    !include ${config.sops.templates."nix-access-tokens.conf".path}
  '';

  # For gh/uv/git/curl. Read at startup; sessionVariables are static and would
  # bake the token into the store.
  programs.zsh.envExtra = ''
    if [[ -r "${config.sops.secrets."github/token".path}" ]]; then
      GITHUB_TOKEN="$(< "${config.sops.secrets."github/token".path}")"
      export GITHUB_TOKEN
      export GH_TOKEN="$GITHUB_TOKEN"
      export UV_GITHUB_TOKEN="$GITHUB_TOKEN"
    fi
  '';
}
