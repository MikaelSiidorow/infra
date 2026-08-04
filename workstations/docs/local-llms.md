# Local LLM

Qwen runs through MLX and llama-swap at `http://127.0.0.1:31415`. The web UI is
at `/ui`. llama-swap loads the model on demand and unloads it after 15 minutes.

```bash
llm-pull
mlx_lm.chat --model mlx-community/Qwen3.6-35B-A3B-nvfp4
tail -f /Users/Shared/llm/logs/llama-swap.log
```

The daemon runs as `_llm` on loopback. Weights live outside the Nix store in the
shared local Hugging Face cache at `/Users/Shared/llm/hf`.

## Updating the model

Change `repo` and `revision` in `lib/llm.nix`, then run:

```bash
make switch
llm-pull
```

## Updating MLX

`pkgs/mlx-metal` combines upstream's prebuilt `mlx` and `mlx-metal` wheels because
nixpkgs builds MLX without Metal. Update the version, wheel URLs, and hashes from
PyPI. The `mlx` wheel is Python-ABI-specific.

## Optional hostname

nix-darwin cannot add one hosts entry without owning the entire hosts file, so
the alias remains manual:

```bash
sudo sh -c 'echo "127.0.0.1       llm.internal" >> /etc/hosts'
```
