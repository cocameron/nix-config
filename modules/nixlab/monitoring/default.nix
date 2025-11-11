{ ... }:

{
  imports = [
    ./victoriametrics.nix
    ./grafana.nix
    ./alloy.nix
    ./exporters.nix
  ];
}
