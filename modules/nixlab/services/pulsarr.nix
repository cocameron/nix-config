{ config, pkgs, ... }:

let
  constants = import ../../common/constants.nix;
in

{
  # Pulsarr - Plex Watchlist to Sonarr/Radarr automation
  # NOTE: Pulsarr container is managed via home-manager to run as a user service
  # See: modules/nixlab/home-manager/home.nix

  # Ensure config directory exists for volume mount
  # Owned by colin (user container needs write access)
  systemd.tmpfiles.rules = [
    "d /home/${constants.primaryUser}/.config/pulsarr 0755 ${constants.primaryUser} users -"
  ];
}
