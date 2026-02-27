# Custom mergiraf build with tree-sitter-po grammar for PO/gettext file support.
#
# This fetches the upstream mergiraf source at a pinned version, injects the
# tree-sitter-po grammar as a path dependency, and patches the language
# registry to enable structure-aware merging of .po/.pot files.
#
# To update mergiraf:
#   1. Bump `version` to the new release tag
#   2. Update `src.hash` (use lib.fakeHash to get the correct one)
#   3. Check if cargoHash needs updating (use lib.fakeHash to verify)
#   4. Verify the patch in postPatch still applies (check supported_langs.rs structure)
#   5. Run: nix build .#packages.aarch64-darwin.mergiraf
#   6. Verify: result/bin/mergiraf languages | grep PO
{
  lib,
  fetchFromGitea,
  rustPlatform,
  runCommand,
}:

let
  version = "0.16.3";

  mergirafSrc = fetchFromGitea {
    domain = "codeberg.org";
    owner = "mergiraf";
    repo = "mergiraf";
    rev = "v${version}";
    hash = "sha256-KlielG8XxOlS5Np8LZT+GMujWw/7EDOwsZHWVjneV3g=";
  };

  treeSitterPoSrc = ../tree-sitter-po;

  # Combined source: mergiraf + tree-sitter-po directory (Cargo.toml/Lock unmodified
  # so that fetchCargoVendor validation passes with the upstream cargoHash)
  src = runCommand "mergiraf-po-src" { } ''
    cp -r ${mergirafSrc} $out
    chmod -R u+w $out

    # Copy tree-sitter-po grammar into the source tree
    cp -r ${treeSitterPoSrc} $out/tree-sitter-po
  '';

in
rustPlatform.buildRustPackage {
  pname = "mergiraf";
  inherit version src;

  # Unchanged from upstream — Cargo.toml/Lock are unmodified at vendor time,
  # so the vendored deps are identical to stock mergiraf.
  cargoHash = "sha256-F6YtOgcAR4fN33j7Ae4ixhTfNctUfgkV3t1I7XJzHHw=";

  postPatch =
    let
      # Unique marker: the vec closing `    ]` followed by `});` only appears once
      # (closing the SUPPORTED_LANGUAGES LazyLock). Earlier `]` at the same indent
      # are followed by `.concat();` or have semicolons.
      vecClose = ''
            ]
        });'';
      poProfile = ''
                LangProfile {
                    name: "PO",
                    alternate_names: &["gettext"],
                    extensions: vec!["po", "pot"],
                    file_names: vec![],
                    language: tree_sitter_po::LANGUAGE.into(),
                    atomic_nodes: vec!["string"],
                    commutative_parents: vec![
                        CommutativeParent::without_delimiters("source_file", "\n\n"),
                        CommutativeParent::without_delimiters("comments", "\n"),
                    ],
                    signatures: vec![
                        signature("message", vec![vec![ChildKind("msgctxt")], vec![ChildKind("msgid")]]),
                        signature("obsolete_entry", vec![vec![ChildKind("obsolete_comment")]]),
                    ],
                    injections: None,
                    flattened_nodes: &[],
                    comment_nodes: &[
                        "translator_comment",
                        "extracted_comment",
                        "reference_comment",
                        "flag_comment",
                        "previous_comment",
                        "obsolete_comment",
                    ],
                },
            ]
        });'';
    in
    ''
      substituteInPlace src/supported_langs.rs --replace-fail \
        ${lib.escapeShellArg vecClose} \
        ${lib.escapeShellArg poProfile}
    '';

  # Cargo.toml/Lock modifications happen in preBuild (after the cargoSetupPostPatchHook
  # validation) so the vendor Cargo.lock matches the unmodified source Cargo.lock.
  # Path deps aren't vendored, so cargo resolves tree-sitter-po from the source tree.
  preBuild = ''
    sed -i '/^tree-sitter-starlark/a tree-sitter-po = { path = "./tree-sitter-po" }' Cargo.toml

    sed -i '/ "tree-sitter-php",$/a \ "tree-sitter-po",' Cargo.lock

    cat >> Cargo.lock << 'LOCKEOF'

[[package]]
name = "tree-sitter-po"
version = "0.1.0"
dependencies = [
 "cc",
 "tree-sitter-language",
]
LOCKEOF
  '';

  cargoBuildFlags = [
    "--bin"
    "mergiraf"
  ];

  # Skip tests — they reference upstream test fixtures and may fail with the patch
  doCheck = false;

  meta = {
    description = "Syntax-aware git merge driver with PO/gettext file support";
    homepage = "https://mergiraf.org/";
    license = lib.licenses.gpl3Only;
    mainProgram = "mergiraf";
  };
}
