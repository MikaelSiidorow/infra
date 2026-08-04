# nixpkgs builds MLX without Metal because its sandbox cannot use Xcode's Metal
# toolchain. Merge upstream's prebuilt mlx and mlx-metal wheels instead.
{
  lib,
  fetchurl,
  buildPythonPackage,
  python,
  unzip,
}:
let
  version = "0.32.0";

  mlxWheels = {
    "3.13" = {
      url = "https://files.pythonhosted.org/packages/4c/a8/7bc999ce5d09dfac8961dcda4ed47e173fca2857492f34599b237380f20d/mlx-0.32.0-cp313-cp313-macosx_26_0_arm64.whl";
      hash = "sha256-QZKi0CAUoTpqEDC/E9+05P4F7D/6R2eO432ikRHiXLE=";
    };
  };

  abi = python.pythonVersion;

  metalWheel = fetchurl {
    url = "https://files.pythonhosted.org/packages/dc/59/65d32520175379df33f107749193aa94ea9db069167a36a1a100ff689f62/mlx_metal-0.32.0-py3-none-macosx_26_0_arm64.whl";
    hash = "sha256-OvdqSY2EgE9mEZgASZ+dFD19/7CHig3Q18KEblhWX9c=";
  };
in
buildPythonPackage {
  pname = "mlx";
  inherit version;
  format = "wheel";

  src = fetchurl (
    mlxWheels.${abi} or (throw "mlx-metal: no wheel pinned for python ${abi}; add one to mlxWheels")
  );

  nativeBuildInputs = [ unzip ];

  # Separate derivations conflict because both wheels populate mlx/.
  postInstall = ''
    unzip -o ${metalWheel} -x '*/__pycache__/*' -d $out/${python.sitePackages}
  '';

  # postInstall satisfies this dependency after the runtime check would run.
  dontCheckRuntimeDeps = true;
  doCheck = false;

  pythonImportsCheck = [ "mlx.core" ];

  meta = {
    description = "MLX array framework with the prebuilt Metal backend";
    homepage = "https://github.com/ml-explore/mlx";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
