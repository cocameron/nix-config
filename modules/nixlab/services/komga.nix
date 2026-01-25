{ config, pkgs, ... }:

let
  constants = import ../../common/constants.nix;
in

{
  services.komga = {
    enable = true;
    port = 25600;  # Default Komga port
    openFirewall = false;  # Using reverse proxy
  };

  # Grant NFS access to komga for media storage
  users.users.komga.extraGroups = [ "rust-users" ];
}
