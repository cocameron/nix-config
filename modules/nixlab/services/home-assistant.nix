{
  lib,
  config,
  pkgs,
  ...
}:

{
  services.home-assistant = {
    enable = true;

    customComponents = [
      pkgs.home-assistant-custom-components.emporia_vue
    ];

    extraComponents = [
      "esphome"
      "met"
      "radio_browser"
      "simplisafe"
      "spotify"
      "apple_tv"
      "google_translate"
      "cast"
      "hue"
      "sonos"
      "plex"
      "homekit_controller"
      "ecobee"
      "isal"
      "zha"
      "hassio"
      "homekit"
      "wemo"
    ];

    config = {
      default_config = { };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "::1"
          "127.0.0.1"
        ];
      };
      zha = {
        usb_path = "/dev/ttyUSB0";
      };
      wemo = {
        discovery = false;
        static = [
          "192.168.1.185"
          "192.168.1.167"
        ];
      };
    };
  };

  # Firewall configuration for HomeKit bridge
  networking.firewall = {
    allowedTCPPorts = [ 21064 ];
    allowedUDPPorts = [ 5353 ];
  };
}
