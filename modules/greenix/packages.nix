{ pkgs, ... }:
{
  config = {
    # Specific packages needed for greenix
    # Common packages (vim, git, python3, pinentry-curses) moved to common/nixos-base.nix
    environment.systemPackages = [
      pkgs.aider-chat-with-help
      pkgs.obsidian
      pkgs.heroic
    ];
  };
}
