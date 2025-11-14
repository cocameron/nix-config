{ lib, ... }:
{
  imports = [
    ../../common/home-manager/home.nix
  ];

  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      theme = "Everforest Dark - Hard";
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome" = {
        "mutter/experimental-features" = [
          "scale-monitor-framebuffer"
          "xwayland-native-scaling"
        ];
      };
    };
  };
}
