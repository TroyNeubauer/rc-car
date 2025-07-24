{
  description = "Base system for raspberry pi 4";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixos-generators, nixos-hardware, ... }: 
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
      piConfig = {
        config = {
          system.stateVersion = "25.05";

          boot.kernelParams = [
            "console=ttyS1,115200n8"
          ];

          environment.systemPackages = with pkgs; [
            curl
            file
            git
            htop
            python3
            ripgrep
            tree
          ];

          services.openssh = {
            enable = true;
          };

          networking = {
            firewall.enable = false;
            useDHCP = false;
            usePredictableInterfaceNames = false;

            interfaces.eth0 = {
              useDHCP = false;
              ipv4.addresses = [{
                address = "10.10.15.1";
                prefixLength = 24;
              }];
            };
          };

          nix.settings = {
            require-sigs = false;
            trusted-users = [ "root" "admin" ];
            experimental-features = "nix-command flakes";
          };

          users.users.admin = {
            password = "admin";
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        };
      };
    in {
      nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hardware-configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          piConfig
        ];
      };
   
      packages.aarch64-linux.sdcard = nixos-generators.nixosGenerate {
        inherit system;
        format = "sd-aarch64";
        modules = [ piConfig ];
      };
    };
}
