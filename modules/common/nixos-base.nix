# Common settings for NixOS systems
{
  pkgs,
  lib,
  config,
  ...
}: # Added lib and config
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

  # Define base configuration for user 'colin'
  # Specific machines can add attributes like SSH keys.
  users.users.colin = {
    isNormalUser = true;
    description = "colin";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # Shell is defined in common/base.nix
    openssh.authorizedKeys.keys = [
      # Common SSH key for colin
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWxH6KYmI6UCzu3j+HhnKMhFcDT1oyMilWG76qXF8yV"
    ];
    linger = true;
  };
}
