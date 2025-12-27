{ pkgs, lib, config, ... }:

let
  # Use shared reverse proxy service definitions from config
  reverseProxyServicesMap = config.nixlab.reverseProxyServices;

  # Generate relabel rules from the service map
  generateRelabelRules = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: ''
      rule {
        source_labels = ["upstream"]
        target_label = "service"
        regex = ".*:${toString value.port}"
        replacement = "${value.friendlyName}"
      }
    '') reverseProxyServicesMap
  );

  # Generate the Alloy configuration
  alloyConfig = pkgs.writeText "config.alloy" ''
    // Prometheus metrics scraping
    prometheus.scrape "nixlab_metrics" {
      targets = [
        // System metrics
        {"__address__" = "127.0.0.1:9100", "job" = "node-exporter", "instance" = "nixlab"},
        {"__address__" = "192.168.1.1:9100", "job" = "node-exporter", "instance" = "openwrt-router"},

        // Cgroup metrics (slices, memory pressure, OOM events)
        {"__address__" = "127.0.0.1:13232", "job" = "cgroup-exporter", "instance" = "nixlab"},

        // VictoriaMetrics self-monitoring
        {"__address__" = "127.0.0.1:8428", "job" = "victoriametrics", "instance" = "nixlab"},

        // Caddy metrics (default admin port)
        {"__address__" = "127.0.0.1:2019", "job" = "caddy", "instance" = "nixlab"},

        // qBittorrent metrics
        {"__address__" = "127.0.0.1:8090", "job" = "qbittorrent", "instance" = "nixlab"},

        // Arr services metrics
        {"__address__" = "127.0.0.1:9191", "job" = "radarr", "instance" = "nixlab"},
        {"__address__" = "127.0.0.1:9192", "job" = "sonarr", "instance" = "nixlab"},
        {"__address__" = "127.0.0.1:9193", "job" = "prowlarr", "instance" = "nixlab"},
      ]
      scrape_interval = "30s"
      metrics_path = "/metrics"

      forward_to = [prometheus.relabel.add_service_names.receiver]
    }

    // Add friendly service names to Caddy reverse proxy metrics
    prometheus.relabel "add_service_names" {
      forward_to = [prometheus.remote_write.victoriametrics.receiver]

      // Dynamically generated rules from reverseProxyServices map
    ${generateRelabelRules}
    }

    // Send metrics to VictoriaMetrics
    prometheus.remote_write "victoriametrics" {
      endpoint {
        url = "http://127.0.0.1:8428/api/v1/write"
      }
    }

    // Systemd journal logs collection
    loki.source.journal "systemd_logs" {
      max_age = "24h"
      labels = {
        job = "systemd-journal",
        instance = "nixlab",
      }
      forward_to = [loki.process.extract_level.receiver]
      relabel_rules = loki.relabel.journal.rules
    }

    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }

      rule {
        source_labels = ["__journal__priority_keyword"]
        target_label = "priority"
      }
    }

    loki.process "extract_level" {
      forward_to = [loki.write.victorialogs.receiver]

      // Stage 1: Use regex to capture the log level from the message body
      // The regex needs to match the format of your log messages.
      // Example: if logs look like "INFO: message" or "[ERROR] message"
      stage.regex {
        // Adjust the regex according to your specific log line format
        expression = "(?i)(?P<log_level>INFO|ERROR|WARNING|DEBUG|CRIT).*?"
      }

      // Stage 2: Use the extracted value to set the 'level' label
      stage.labels {
        values = {
          level = "log_level", // Map the captured group 'log_level' to the 'level' label
        }
      }
    }

    // Send logs to VictoriaLogs
    loki.write "victorialogs" {
      endpoint {
        url = "http://127.0.0.1:9428/insert/loki/api/v1/push"
      }
    }
  '';
in
{
  # Grafana Alloy for unified metrics and logs collection
  services.alloy = {
    enable = true;
    configPath = "/etc/alloy/config.alloy";
    extraFlags = [ "--disable-reporting" ];
  };

  # Alloy configuration for metrics and logs (dynamically generated)
  environment.etc."alloy/config.alloy".source = alloyConfig;
}
