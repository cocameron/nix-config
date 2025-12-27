{ pkgs, ... }:

{
  udpbd-vexfat = pkgs.rustPlatform.buildRustPackage rec {
    pname = "udpbd-vexfat";
    version = "0.2.0";

    src = pkgs.fetchFromGitHub {
      owner = "awaken1ng";
      repo = "udpbd-vexfat";
      rev = "v${version}";
      sha256 = "sha256-kFMbUltohAGjT4WK+I6UPDugsnX4c2Grc6x0DwpovBc=";
      fetchSubmodules = true;
    };

    cargoHash = "sha256-aBf/sQ9V5fEYgVOwYXhxhxqg/ESszNZXjc0uAVW0/Bk=";

    meta = with pkgs.lib; {
      description = "UDP Block Device server for PS2 OPL (Open PS2 Loader) with virtual exFAT filesystem support";
      homepage = "https://github.com/awaken1ng/udpbd-vexfat";
      license = licenses.unfree; # License not specified in repo
      platforms = platforms.linux;
    };
  };
}
