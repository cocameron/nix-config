{ ... }:

{
  # Grafana Alloy for unified metrics and logs collection
  services.alloy = {
    enable = true;
    configPath = "/etc/alloy/config.alloy";
  };

  # Alloy configuration for metrics and logs
  environment.etc."alloy/config.alloy".source = ./config.alloy;
}
