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

  # Unpackerr Service
  systemd.services.unpackerr = {
    description = "Unpackerr extracts downloads for Radarr, Sonarr, Lidarr, and Readarr";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = constants.primaryUser;
      Group = "users";
      ExecStart = "${unpackerrPkg.unpackerr}/bin/unpackerr -c /home/${constants.primaryUser}/.config/unpackerr/unpackerr.conf";
      Restart = "on-failure";
      RestartSec = "5s";
      WorkingDirectory = "/home/${constants.primaryUser}";
      Environment = [
        "TZ=${constants.timezone}"
      ];
    };
  };

  # Profilarr - Configuration management for Radarr/Sonarr
  virtualisation.oci-containers.containers.profilarr = {
    image = "santiagosayshey/profilarr:latest";
    extraOptions = [ "--network=host" ];
    volumes = [
      "/var/lib/profilarr:/config"
    ];
    environment = {
      TZ = constants.timezone;
    };
  };

  # Ensure profilarr data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/profilarr 0755 root root -"
  ];

  # iSponsorBlockTV - Skip SponsorBlock segments on YouTube TV
  systemd.services.isponsorblocktv = {
    description = "SponsorBlock client for YouTube TV";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = constants.primaryUser;
      Group = "users";
      ExecStart = "${pkgs-unstable.isponsorblocktv}/bin/iSponsorBlockTV";
      Restart = "on-failure";
      RestartSec = "10s";
      WorkingDirectory = "/home/${constants.primaryUser}";
      StateDirectory = "isponsorblocktv";
      StateDirectoryMode = "0755";
    };
  };

  # Add packages to system
  environment.systemPackages = [
    unpackerrPkg.unpackerr
    pkgs-unstable.isponsorblocktv
  ];
}
