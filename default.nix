{ pkgs ? import <nixpkgs> { } }: with pkgs; with lib; let
  cmake-lib = callPackage ./derivation.nix { };
  shell = mkShell {
    nativeBuildInputs = [ cmake ];
  };
in cmake-lib // {
  inherit shell;
}
