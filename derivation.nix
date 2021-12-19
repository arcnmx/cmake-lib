{ stdenvNoCC
, cmake
, nix-gitignore
, cmake-lib ? buildPackages.callPackage ./derivation.nix { inherit stdenvNoCC cmake nix-gitignore; }, buildPackages
}: stdenvNoCC.mkDerivation {
  pname = "cmake-lib";
  version = "0.1.0";

  doCheck = false;
  nativeBuildInputs = [ cmake ];

  src = nix-gitignore.gitignoreSourcePure [ ''
    *.nix
  '' ./.gitignore ] ./.;

  passthru.tests.simple = stdenvNoCC.mkDerivation {
    pname = "cmake-lib-example-simple";
    version = "0.0.1";

    nativeBuildInputs = [ cmake cmake-lib ];

    src = nix-gitignore.gitignoreSourcePure [ ''
    '' ./.gitignore ] ./examples/simple;

    cmakeFlags = [
      "-DGLOBAL=ON"
      "-DCMAKE_FIND_DEBUG_MODE=ON"
    ];
  };
}
