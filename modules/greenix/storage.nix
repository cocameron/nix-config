{ lib, ... }:

{
  # NFS client support
  services.rpcbind.enable = true;

  # NFS mount for media storage
  fileSystems."/mnt/nfs" = {
    device = "192.168.1.205:/rust";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "tcp"
      "noatime"
      "nodiratime"
      "rw"
      "soft"
      "timeo=15"
      "rsize=262144"
      "wsize=262144"
      "nolock"
      "local_lock=none"
      "x-systemd.automount"
    ];
  };

  # User group for NFS access
  users.groups.rust-users = { };
}
