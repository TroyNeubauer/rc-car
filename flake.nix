{
  description = "Base system for Raspberry Pi 4";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, nixos-generators, nixos-hardware, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      overlay = final: prev: { god = prev.callPackage ./pi/god.nix {}; };
      mkPkgs = system: import nixpkgs { inherit system; overlays = [ overlay ]; };
    in
    flake-utils.lib.eachSystem systems (system:
      let pkgs = mkPkgs system;
      in
      {
        devShells = {
          default = pkgs.mkShell { buildInputs = [ pkgs.god ]; };
        };
        packages = pkgs.lib.optionalAttrs (system == "aarch64-linux") {
          # For flashing initial pi closure to sd-card
          pi-sdcard = nixos-generators.nixosGenerate {
            inherit system pkgs;
            format = "sd-aarch64";
            modules = [ ./pi/configuration.nix ];
          };
        } // { inherit (pkgs) god; };
      }
    ) // {
      nixosConfigurations = {
        pi = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./pi/hardware-configuration.nix
            nixos-hardware.nixosModules.raspberry-pi-4
            ./pi/configuration.nix
            { nixpkgs.overlays = [ overlay ]; }
          ];
        };
      };
    };
}
