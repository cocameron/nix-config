{ ... }:

{
  # VictoriaMetrics - lightweight TSDB
  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "30d"; # 30 days retention
    extraOptions = [
      "-memory.allowedPercent=40"  # Use max 40% of system RAM
      "-search.maxMemoryPerQuery=100MB"  # Limit query memory
    ];
  };

  # VictoriaLogs for log storage (lightweight alternative to Loki)
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:9428";
    extraOptions = [
      "-storageDataPath=/var/lib/victorialogs"
      "-retentionPeriod=30d"
    ];
  };
}
