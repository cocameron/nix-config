{ config, pkgs, lib, ... }:

let
  constants = import ../../common/constants.nix;
in
{
  # qui - Modern web UI for qBittorrent
  systemd.services.qui = {
    description = "qui - Fast, modern web interface for qBittorrent";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.qui}/bin/qui serve";
      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      DynamicUser = true;
      StateDirectory = "qui";
      WorkingDirectory = "/var/lib/qui";

      # Sandboxing
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
    };

    environment = {
      QUI__HOST = "127.0.0.1";
      QUI__PORT = "7476";
      QUI__BASE_URL = "/";
      QUI__LOG_LEVEL = "info";
    };
  };
}
