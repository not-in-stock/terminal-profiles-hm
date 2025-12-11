{
  description = "Home Manager module: Terminal.app profiles with readable colors/fonts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    hmModule = import ./modules/terminal-profiles.nix { inherit self; };
  in {
    homeManagerModules.terminal-profiles = hmModule;
  };
}
