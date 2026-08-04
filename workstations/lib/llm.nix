{ pkgs-unstable, lib }:
let
  pyPkgs = pkgs-unstable.python313Packages;

  # nixpkgs builds MLX without Metal because its sandbox cannot use Xcode's
  # Metal toolchain. This package merges upstream's prebuilt Metal wheel.
  mlx-metal = pyPkgs.callPackage ../pkgs/mlx-metal { };
in
rec {
  # Avoid common development ports while staying below macOS's ephemeral range.
  port = 31415;
  cacheDir = "/Users/Shared/llm";
  logDir = "${cacheDir}/logs";
  homeDir = "${cacheDir}/home";

  serviceUser = "_llm";
  serviceUid = 601;

  model = {
    name = "qwen3.6-35b";
    repo = "mlx-community/Qwen3.6-35B-A3B-nvfp4";
    revision = "9c1a3a223ddd8a3425212cc421056614f149cf0f";
    description = "Qwen3.6 35B-A3B MoE, 4-bit — 126 tok/s, 21.5 GB";
  };

  modelPath =
    "${cacheDir}/hf/hub/models--${lib.replaceStrings [ "/" ] [ "--" ] model.repo}"
    + "/snapshots/${model.revision}";

  pyEnv = pkgs-unstable.python313.withPackages (_: [
    ((pyPkgs.mlx-lm.override { mlx = mlx-metal; }).overridePythonAttrs (old: {
      # mlx-lm omits sentencepiece, and one GPU tolerance test fails with Metal.
      doCheck = false;
      dependencies = old.dependencies ++ [ pyPkgs.sentencepiece ];
    }))
    pyPkgs.huggingface-hub
  ]);

  swapConfig = (pkgs-unstable.formats.yaml { }).generate "llama-swap.yaml" {
    logLevel = "info";
    healthCheckTimeout = 900;
    models.${model.name} = {
      inherit (model) description;
      # Otherwise mlx-lm treats the public catalog name as a Hugging Face repo.
      useModelName = modelPath;
      cmd = lib.concatStringsSep " " [
        "${pyEnv}/bin/mlx_lm.server"
        "--model ${modelPath}"
        "--port \${PORT}"
        "--max-tokens 32768"
        "--prompt-cache-size 8"
      ];
      checkEndpoint = "/v1/models";
      ttl = 900;
    };
  };
}
