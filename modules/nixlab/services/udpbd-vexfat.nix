{ config, pkgs, lib, ... }:

let
  constants = import ../../common/constants.nix;
  udpbdVexfatPkg = pkgs.callPackage ../packages/udpbd-vexfat.nix {};
in
{
  # udpbd-vexfat - UDP Block Device server for PS2 OPL
  systemd.services.udpbd-vexfat = {
    description = "UDP Block Device server for PS2 OPL with virtual exFAT filesystem";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${udpbdVexfatPkg.udpbd-vexfat}/bin/udpbd-vexfat /mnt/nfs/content/opl";
      Restart = "on-failure";
      RestartSec = "10s";

      # Run as primary user to access NFS mount
      User = constants.primaryUser;
      Group = "users";

      # Sandboxing
      PrivateTmp = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RemoveIPC = true;
    };
  };

  # Allow unfree license for this package
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "udpbd-vexfat"
  ];
}
