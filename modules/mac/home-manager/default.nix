{ lib, pkgs, ... }:
{
  imports = [
    ./ghostty.nix
  ];

  home.packages = with pkgs; [
    zed-editor
  ];

  programs.vscode = {
    enable = true;
  };

  # macOS-specific settings
  targets.darwin.defaults = {
    # Global macOS settings
    NSGlobalDomain = {
      # Add your macOS preferences here
      # Examples:
      # AppleShowAllExtensions = true;
      # InitialKeyRepeat = 15;
      # KeyRepeat = 2;
    };

    # Finder settings
    "com.apple.finder" = {
      # Add Finder preferences here
      # Examples:
      # ShowPathbar = true;
      # FXEnableExtensionChangeWarning = false;
    };

    # Dock settings
    "com.apple.dock" = {
      # Add Dock preferences here
      # Examples:
      # autohide = true;
      # orientation = "left";
      # tilesize = 48;
    };
  };
}
