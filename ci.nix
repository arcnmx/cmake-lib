{ pkgs, lib, ... }: with lib; let
  cmake-lib = import ./. { inherit pkgs; };
in {
  name = "cmake-lib";
  ci.gh-actions.enable = true;
  cache.cachix.arc.enable = true;
  channels = {
    nixpkgs = "21.11";
  };
  tasks = {
    build.inputs = [
      cmake-lib
    ] ++ attrValues cmake-lib.tests;
  };
}
