{ config, pkgs, ... }:

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
      user = constants.primaryUser;
    };

  # Arr Services
  services.radarr = {
    enable = true;
    user = constants.primaryUser;
  };

  services.sonarr = {
    enable = true;
    user = constants.primaryUser;
  };

  services.prowlarr = {
    enable = true;
  };

  services.overseerr = {
    enable = true;
    port = 5055;
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
