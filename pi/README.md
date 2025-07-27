
# PI

The PI assigns `10.10.15.1/24` to its ethernet port, allowing for easy hardlinking.

### Provisioning a PI

Build bootable image for SD card:
```
nix build --system aarch64-linux .#sdcard --print-out-paths
```

Copy to SD card:
```
zstdcat result/sd-image/nixos-image-sd-card-25.05.20250721.92c2e04-aarch64-linux.img.zst | sudo dd of=/dev/sdb bs=4M status=progress oflag=sync
```

### Post Install
```
nixos-rebuild switch --flake .#pi --target-host admin@10.10.15.1
```

Building the closure (for manual nix copy)
```
nix build .#nixosConfigurations.pi.config.system.build.toplevel
```

Or on the PI itself (its actually pretty fast!):
```
sudo nixos-rebuild switch --flake .#pi
```

