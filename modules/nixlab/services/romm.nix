{ config, pkgs, ... }:

{
  # Romm - ROM Manager
  virtualisation.oci-containers.containers.romm-db = {
    image = "mariadb:latest";
    autoStart = true;
    environment = {
      MARIADB_DATABASE = "romm";
      MARIADB_USER = "romm-user";
    };
    environmentFiles = [
      config.sops.templates."romm-db-env".path
    ];
    volumes = [
      "romm-mysql-data:/var/lib/mysql"
    ];
    extraOptions = [
      "--health-cmd=healthcheck.sh --connect --innodb_initialized"
      "--health-start-period=30s"
      "--health-interval=10s"
      "--health-timeout=5s"
      "--health-retries=5"
    ];
  };

  virtualisation.oci-containers.containers.romm = {
    image = "rommapp/romm:latest";
    autoStart = true;
    dependsOn = [ "romm-db" ];
    environment = {
      DB_HOST = "romm-db";
      DB_NAME = "romm";
      DB_USER = "romm-user";
      PLAYMATCH_API_ENABLED="true";
      HASHEOUS_API_ENABLED = "true";
    };
    environmentFiles = [
      config.sops.templates."romm-env".path
    ];
    volumes = [
      "romm-resources:/romm/resources"
      "romm-redis-data:/redis-data"
      "/mnt/nfs/content/media/games:/romm/library"
      "/mnt/storage/romm/assets:/romm/assets"
      "/mnt/storage/romm/config:/romm/config"
    ];
    ports = [
      "8091:8080"
    ];
    extraOptions = [ ];
  };

  # Ensure directories exist for volume mounts
  systemd.tmpfiles.rules = [
    "d /mnt/storage/romm 0755 root root -"
    "d /mnt/storage/romm/assets 0755 root root -"
    "d /mnt/storage/romm/config 0755 root root -"
  ];
}
