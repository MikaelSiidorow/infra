# Zed editor configuration.
{
  pkgs,
  config,
  isDarwin ? false,
  ...
}:
let
  zedLsp = path: arguments: {
    binary = {
      inherit path arguments;
    };
  };
  vscodeLangServer = name: zedLsp "${pkgs.vscode-langservers-extracted}/bin/${name}" [ "--stdio" ];
  nodeLangServer =
    package: binary: arguments:
    zedLsp "${package}/bin/${binary}" arguments;
in
{
  programs.zed-editor = {
    enable = true;
    package = if isDarwin then pkgs.zed-editor else config.lib.nixGL.wrap pkgs.zed-editor;
    extraPackages =
      with pkgs;
      [
        bash-language-server
        dockerfile-language-server
        nil
        nixd
        nodejs
        package-version-server
        ruff
        rust-analyzer
        tailwindcss-language-server
        typescript-language-server
        vscode-langservers-extracted
        vtsls
        yaml-language-server
      ]
      ++ pkgs.lib.optionals (!isDarwin) [
        nmap
        tinymist
      ];
    extensions = [
      "dockerfile"
      "git-firefly"
      "html"
      "nix"
      "oxc"
      "toml"
    ]
    ++ pkgs.lib.optionals (!isDarwin) [
      "gdscript"
      "lua"
      "typst"
    ];
    userSettings = {
      auto_update = false;
      disable_ai = true;
      show_edit_predictions = false;
      max_tabs = 1;
      title_bar = {
        show_sign_in = false;
      };
      collaboration_panel = {
        button = false;
      };
      node = {
        ignore_system_version = false;
        path = "${pkgs.nodejs}/bin/node";
        npm_path = "${pkgs.nodejs}/bin/npm";
      };
      lsp = {
        json-language-server = vscodeLangServer "vscode-json-language-server";
        vscode-css-language-server = vscodeLangServer "vscode-css-language-server";
        vscode-html-language-server = vscodeLangServer "vscode-html-language-server";
        yaml-language-server = nodeLangServer pkgs.yaml-language-server "yaml-language-server" [
          "--stdio"
        ];
        bash-language-server = nodeLangServer pkgs.bash-language-server "bash-language-server" [ "start" ];
        dockerfile-language-server = nodeLangServer pkgs.dockerfile-language-server "docker-langserver" [
          "--stdio"
        ];
        nil = zedLsp "${pkgs.nil}/bin/nil" [ ];
        nixd = zedLsp "${pkgs.nixd}/bin/nixd" [ ];
        package-version-server = zedLsp "${pkgs.package-version-server}/bin/package-version-server" [ ];
        rust-analyzer = zedLsp "${pkgs.rust-analyzer}/bin/rust-analyzer" [ ];
        ruff = zedLsp "${pkgs.ruff}/bin/ruff" [ "server" ];
        vtsls = nodeLangServer pkgs.vtsls "vtsls" [ "--stdio" ];
        typescript-language-server =
          nodeLangServer pkgs.typescript-language-server "typescript-language-server"
            [ "--stdio" ];
        tailwindcss-language-server =
          nodeLangServer pkgs.tailwindcss-language-server "tailwindcss-language-server"
            [ "--stdio" ];
      }
      // pkgs.lib.optionalAttrs (!isDarwin) {
        tinymist = (zedLsp "${pkgs.tinymist}/bin/tinymist" [ "lsp" ]) // {
          settings = {
            exportPdf = "onSave";
            outputPath = "$root/$name";
          };
        };
      };
    };
  };
}
