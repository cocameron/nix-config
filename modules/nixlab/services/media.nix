{ config, pkgs, pkgs-unstable, ... }:

let
  constants = import ../../common/constants.nix;
  unpackerrPkg = pkgs.callPackage ../packages/unpackerr.nix {};
in

{
  # Plex Media Server with PlexPass
  services.plex = let
    plexpass = pkgs.plex.override {
      plexRaw = pkgs.plexRaw.overrideAttrs(old: rec {
        version = "1.42.2.10156-f737b826c";
        src = pkgs.fetchurl {
          url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
          sha256 = "sha256-1ieh7qc1UBTorqQTKUQgKzM96EtaKZZ8HYq9ILf+X3M=";
        };
      });
    };
  in {
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

  services.lidarr = {
    enable = true;
    user = constants.primaryUser;
    settings = {
      update = {
        mechanism = "builtIn";
      };
    };
  };

  services.prowlarr = {
    enable = true;
  };

  # Unpackerr and iSponsorBlockTV moved to home-manager (home.nix)

  # Allow Plex on LAN interface only (not exposed to internet)
  networking.firewall.interfaces."ens18".allowedTCPPorts = [ 32400 ];
}
