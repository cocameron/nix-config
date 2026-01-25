{ config, pkgs, ... }:

let
  constants = import ../../common/constants.nix;
in

{
  services.audiobookshelf = {
    enable = true;
    port = 13378;
  };

  users.users.audiobookshelf.extraGroups = [ "rust-users" ];
}
