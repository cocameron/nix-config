{ pkgs, ... }:
{
  config = {
    # Specific packages needed for greenix
    # Common packages (vim, git, python3, pinentry-curses) moved to common/nixos-base.nix
    environment.systemPackages = with pkgs; [
      aider-chat-with-help
    ];
  };
}
