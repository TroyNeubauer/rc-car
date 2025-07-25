{ config, pkgs, lib, ... }:
{
  # NOTE: dont import hardware-configuration.nix like usual here, since that would conflict with nixosGenerate's config
  
  boot = {
    initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];
    kernelModules = [ "brcmfmac" "brcmutil" ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    raspberrypiWirelessFirmware
  ];

  users.users.admin = {
    password = "admin";
    isNormalUser = true;
    extraGroups = [ "wheel" "plugdev" "disk" "video" ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    curl
    file
    git
    htop
    ripgrep
    tree
    wireguard-tools
    (python312.withPackages (ps: with ps; [
      opendbc
      panda
    ])
  ];

  programs = {
    fish.enable = true;
    neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };
  };

  services.openssh = {
    enable = true;
  };

  networking = {
    hostName = "rc_car_alpha";
    firewall.enable = false;

    usePredictableInterfaceNames = false;
    wireless.enable = true; 
    wireless.interfaces = [ "wlan0" ];

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

  systemd.services.god = {
    description = "GO Daemon (for driving cars)";
    wants = [ "network.target" ];
    after = [ "network.target" ];
    enable = lib.mkDefault true;

    serviceConfig = {
      ExecStart = "${pkgs.god}/bin/god";
      Restart = "on-failure";
      User = "admin";
      Group = "wheel";
    };
  };

  nix.settings = {
    require-sigs = false;
    trusted-users = [ "root" "admin" ];
    experimental-features = "nix-command flakes";
    download-buffer-size = 68719476736;# 64MB
  };

  system.stateVersion = "25.05";
}
