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

          boot = {
            initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
            loader = {
              grub.enable = false;
              generic-extlinux-compatible.enable = true;
            };
          };

          environment.systemPackages = with pkgs; [
            curl
            file
            git
            htop
            python3
            ripgrep
            tree
            wireguard-tools
          ];

          services.openssh = {
            enable = true;
          };

          networking = {
            hostName = "rc_car_alpha";
            firewall.enable = false;

            usePredictableInterfaceNames = false;
            wireless.enable = true; 

            interfaces.eth0 = {
              useDHCP = true;
              ipv4.addresses = [{
                address = "10.10.15.1";
                prefixLength = 24;
              }];
            };

            wireguard.interfaces = {
              wg0 = {
                ips = [ "10.56.0.30/24" ];
                listenPort = 51820;

                privateKeyFile = "/etc/secrets/wg0-private";
                # publicKey = "0N/CQgahzq1uHCJe+jCX7diG1Q52N8d1oW/bm4aE/3o=";

                peers = [
                  {
                    publicKey = "3Z7PGFd8VsaSZnI/8aI6COKETIW5IHD+ew50DnlHRko=";
                    allowedIPs = [ "10.56.0.0/24" ];
                    endpoint = "147.182.239.30:51820";
                    persistentKeepalive = 25;
                  }
                ];
              };
            };
          };

          nix.settings = {
            require-sigs = false;
            trusted-users = [ "root" "admin" ];
            experimental-features = "nix-command flakes";
            download-buffer-size = 68719476736;# 64MB
          };

          programs = {
            fish.enable = true;
            neovim = {
              enable = true;
              vimAlias = true;
              defaultEditor = true;
            };
          };

          users.users.admin = {
            password = "admin";
            isNormalUser = true;
            extraGroups = [ "wheel" "plugdev" "disk" "video" ];
            shell = pkgs.fish;
          };
        };
      };
    in {
      nixosConfigurations.pi = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hardware-configuration.nix
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
