{ pkgs, ... }:

{
  unpackerr = pkgs.stdenv.mkDerivation rec {
    pname = "unpackerr";
    version = "0.14.5";

    src = pkgs.fetchurl {
      url = "https://github.com/Unpackerr/unpackerr/releases/download/v${version}/unpackerr.amd64.linux.gz";
      sha256 = "08spf1afi6sgg8321m3fbd0g8rxi45vfrhaf6v298cdqlwir1l3v";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      gunzip -c $src > $out/bin/unpackerr
      chmod +x $out/bin/unpackerr
    '';

    meta = with pkgs.lib; {
      description = "Extracts downloads for Radarr, Sonarr, Lidarr, Readarr, and/or a watch folder";
      homepage = "https://github.com/Unpackerr/unpackerr";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
}
