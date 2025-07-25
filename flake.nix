{
  description = "Base system for Raspberry Pi 4";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, nixos-generators, nixos-hardware, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlay = final: prev: { god = prev.callPackage ./pi/god.nix {}; };
        pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
      in {
        packages = (let base = { god = pkgs.god; }; in
          if system == "aarch64-linux" then
            base // {
              sdcard = nixos-generators.nixosGenerate {
                inherit system;
                format = "sd-aarch64";
                pkgs = pkgs;
                modules = [ ./pi/configuration.nix ];
              };
            }
          else base);
        devShells.default = pkgs.mkShell { buildInputs = [ pkgs.god ]; };
        nixosConfigurations =
          if system == "aarch64-linux" then {
            pi = pkgs.lib.nixosSystem {
              system = "aarch64-linux";
              modules = [
                ./pi/hardware-configuration.nix
                nixos-hardware.nixosModules.raspberry-pi-4
                ./pi/configuration.nix
              ];
            };
          }
          else {};
      }
    );
}
