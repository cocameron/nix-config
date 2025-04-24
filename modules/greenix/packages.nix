{ pkgs, specialArgs, ... }: # Use specialArgs
let
  # Access pkgs-unstable via specialArgs
  inherit (specialArgs) pkgs-unstable;
  unstable = with pkgs-unstable; [
    aider-chat-with-help
  ];
in
{
  config = {
    # Specific packages needed for greenix
    # Common packages (vim, git, python3, pinentry-curses) moved to common/nixos-base.nix
    environment.systemPackages = unstable; # Add only unstable packages here
  };
}
