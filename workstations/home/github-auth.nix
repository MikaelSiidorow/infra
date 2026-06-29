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

  # uv only. Setting GITHUB_TOKEN/GH_TOKEN would shadow gh's keyring login,
  # which holds the real scopes.
  programs.zsh.envExtra = ''
    if [[ -r "${config.sops.secrets."github/token".path}" ]]; then
      export UV_GITHUB_TOKEN="$(< "${config.sops.secrets."github/token".path}")"
    fi
  '';
}
