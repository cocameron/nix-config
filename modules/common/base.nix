{ pkgs, lib, ... }:
let
  constants = import ./constants.nix;
in
{
  time.timeZone = constants.timezone;
  nixpkgs.config.allowUnfree = true;
  nix = {
    gc =
      {
        automatic = true;
        options = "--delete-older-than 7d";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        interval = {
          Weekday = 0;
          Hour = 0;
          Minute = 0;
        };
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        dates = "weekly";
      };
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" constants.primaryUser ];
    };
    optimise = {
      automatic = true;
    };
  };

  users.users.${constants.primaryUser} = {
    shell = pkgs.zsh;
  };

  # Enable system-wide zsh
  programs.zsh.enable = true;
}
