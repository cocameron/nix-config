{ pkgs, lib, ... }:
{
  time.timeZone = "America/Los_Angeles";
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
    };
    optimise = {
      automatic = true;
    };
  };

  users.users.colin = {
    shell = pkgs.zsh;
  };

  # Enable system-wide zsh
  programs.zsh.enable = true;
}
