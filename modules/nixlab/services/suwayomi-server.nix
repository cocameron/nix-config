{ config, pkgs, ... }:

let
  constants = import ../../common/constants.nix;
in

{
  services.suwayomi-server = {
    enable = true;
    openFirewall = false;  # Using reverse proxy
    settings.server = {
      port = 4567;  # Default Suwayomi port
    };
  };

  # Grant NFS access to suwayomi for media storage
  users.users.suwayomi.extraGroups = [ "rust-users" ];
}
