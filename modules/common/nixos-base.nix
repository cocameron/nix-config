# Common settings for NixOS systems
{
  pkgs,
  lib,
  config,
  ...
}:
let
  constants = import ./constants.nix;
in
{
  # Default hostname, can be overridden by specific machine configs
  networking.hostName = lib.mkDefault "nixos";
  # Enable networking with NetworkManager by default
  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true;

  # Don't ask for passwords for wheel users
  security.sudo.wheelNeedsPassword = false;

  # Common packages needed across Linux systems
  environment.systemPackages = with pkgs; [
    pinentry-curses # Common pinentry for GPG/SSH agent
    vim # Basic editor
    git # Version control
    python3 # Often needed for various tools/scripts
  ];

  # Enable mDNS for `hostname.local` addresses
  # Use nssmdns = true; for both v4/v6 resolution
  services.avahi = {
    enable = true;
    # Enable both IPv4 and IPv6 mDNS resolution via nss-mdns
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Define base configuration for primary user
  # Specific machines can add attributes like SSH keys.
  users.users.${constants.primaryUser} = {
    isNormalUser = true;
    description = constants.primaryUser;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # Shell is defined in common/base.nix
    openssh.authorizedKeys.keys = [
      constants.sshKeys.colin
    ];
    linger = true;
  };
}
