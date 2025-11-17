{ config, pkgs, ... }:

{
  # Romm - ROM Manager
  # NOTE: Romm containers are now managed via home-manager to run as user services
  # See: modules/nixlab/home-manager/home.nix

  # Ensure directories exist for volume mounts
  # Owned by colin (user containers need write access)
  systemd.tmpfiles.rules = [
    "d /mnt/storage/romm 0755 colin users -"
    "d /mnt/storage/romm/assets 0755 colin users -"
    "d /mnt/storage/romm/config 0755 colin users -"
  ];
}
