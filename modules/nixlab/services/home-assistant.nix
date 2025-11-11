{ lib, ... }:

{
  services.home-assistant = {
    enable = true;

    extraComponents = [
      "esphome"
      "met"
      "radio_browser"
      "spotify"
      "apple_tv"
      "google_translate"
      "cast"
      "hue"
      "sonos"
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
    };
  };

  # Firewall configuration for HomeKit bridge
  networking.firewall = {
    allowedTCPPorts = [ 21064 ];
    allowedUDPPorts = [ 5353 ];
  };
}
