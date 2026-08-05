{
  pkgs,
  pkgs-unstable,
  config,
  inputs,
  lib,
  ...
}:
let
  llm = import ../lib/llm.nix { inherit pkgs-unstable lib; };
  inherit (llm) pyEnv cacheDir model;
  homeDir = config.home.homeDirectory;
  opencodePackage = inputs.opencode-nix.packages.${pkgs-unstable.stdenv.hostPlatform.system}.default;
  opencodeSandbox = pkgs.callPackage ../pkgs/opencode-sandbox { };

  withCache = "HF_HOME=${cacheDir}/hf";

  withToken = ''
    tokenFile=${config.sops.secrets."hf/token".path}
    if [ -r "$tokenFile" ]; then
      HF_TOKEN=$(cat "$tokenFile")
      export HF_TOKEN
    fi
  '';

  # Expose MLX entry points without replacing the regular Python environment.
  llmTools = pkgs-unstable.runCommand "llm-tools" { } ''
    mkdir -p $out/bin
    for b in mlx_lm.chat mlx_lm.generate mlx_lm.benchmark mlx_lm.perplexity \
             mlx_lm.lora mlx_lm.convert hf; do
      printf '#!/bin/sh\nexec env ${withCache} ${pyEnv}/bin/%s "$@"\n' "$b" > $out/bin/"$b"
      chmod +x $out/bin/"$b"
    done
  '';

  llm-pull = pkgs-unstable.writeShellApplication {
    name = "llm-pull";
    runtimeInputs = [ pyEnv ];
    text = ''
      export ${withCache}
      ${withToken}
      hf download '${model.repo}' --revision '${model.revision}'
    '';
  };

  opencode = opencodeSandbox.wrap {
    opencode = opencodePackage;
    homeDirectory = homeDir;
    username = config.home.username;
  };
in
{
  home.packages = [
    llmTools
    llm-pull
    opencode
  ];

  home.activation.testOpencodeSandbox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${opencodeSandbox.test}/bin/opencode-sandbox-test
  '';

  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.local = {
      npm = "@ai-sdk/openai-compatible";
      name = "Local MLX";
      options.baseURL = "http://127.0.0.1:${toString llm.port}/v1";
      models.${model.name} = {
        name = model.description;
        limit = {
          context = 262144;
          output = 32768;
        };
      };
    };
  };
}
