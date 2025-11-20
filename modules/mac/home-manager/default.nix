{ lib, ... }:
{
  imports = [
    ./ghostty.nix
  ];

  programs.vscode = {
    enable = true;
  };
}
