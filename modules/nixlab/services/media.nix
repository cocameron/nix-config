{ config, pkgs, lib, ... }:

let
  constants = import ../../common/constants.nix;
  unpackerrPkg = pkgs.callPackage ../packages/unpackerr.nix { };
in

{
  # Plex Media Server with PlexPass
  services.plex =
    let
      plexpass = pkgs.plex.override {
        plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.42.2.10156-f737b826c";
          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            sha256 = "sha256-1ieh7qc1UBTorqQTKUQgKzM96EtaKZZ8HYq9ILf+X3M=";
          };
        });
      };
    in
    {
      enable = true;
      package = plexpass;
    };

  # Arr Services
  services.radarr = {
    enable = true;
  };

  services.sonarr = {
    enable = true;
  };

  # Grant NFS access to media services
  # NFS export uses all_squash to map all client UIDs to rust-users (UID/GID 1000)
  users.users.plex.extraGroups = [ "rust-users" ];
  users.users.radarr.extraGroups = [ "rust-users" ];
  users.users.sonarr.extraGroups = [ "rust-users" ];

  services.prowlarr = {
    enable = true;
  };

  # Music Assistant
  services.music-assistant = {
    enable = true;
    providers = [ "plex" "sonos" ];
  };

  # Unpackerr and iSponsorBlockTV moved to home-manager (home.nix)

  # Allow Plex and Music Assistant on LAN interface only (not exposed to internet)
  networking.firewall.interfaces."ens18".allowedTCPPorts = [
    32400  # Plex
    8095   # Music Assistant web interface
    8097   # Music Assistant stream server
  ];
}
