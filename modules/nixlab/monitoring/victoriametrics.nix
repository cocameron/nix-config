{ ... }:

{
  # VictoriaMetrics - lightweight TSDB
  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "14d"; # 14 days retention (reduced from 30d)
    extraOptions = [
      "-memory.allowedPercent=30"  # Use max 30% of system RAM (reduced from 40%)
      "-search.maxMemoryPerQuery=75MB"  # Limit query memory (reduced from 100MB)
    ];
  };

  # VictoriaLogs for log storage (lightweight alternative to Loki)
  services.victorialogs = {
    enable = true;
    listenAddress = "127.0.0.1:9428";
    extraOptions = [
      "-storageDataPath=/var/lib/victorialogs"
      "-retentionPeriod=14d"  # Reduced from 30d
    ];
  };
}
