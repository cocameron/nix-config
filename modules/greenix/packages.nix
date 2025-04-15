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
    # Some sane packages we need on every system
    # Specific packages needed for greenix (pinentry-curses moved to common)
    environment.systemPackages =
      with pkgs;
      [
        vim # for emergencies
        git # for pulling nix flakes
        python3 # for ansible
      ]
      ++ unstable; # Add unstable packages here
  };
}
