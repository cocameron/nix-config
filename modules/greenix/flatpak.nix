{ pkgs, ... }:
{
  config = {
    # Enable Flatpak support
    services.flatpak.enable = true;

    # Install flatpak from local file on system activation
    system.activationScripts.installAlderonLauncher = {
      text = ''
        # Add Flathub repository if not exists (needed for runtimes)
        if ! ${pkgs.flatpak}/bin/flatpak remote-list | grep -q "^flathub"; then
          echo "Adding Flathub repository..."
          ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        fi

        # Install required runtime
        RUNTIME="org.freedesktop.Platform/x86_64/24.08"
        if ! ${pkgs.flatpak}/bin/flatpak list --runtime | grep -q "org.freedesktop.Platform.*24.08"; then
          echo "Installing FreeDesktop runtime 24.08..."
          ${pkgs.flatpak}/bin/flatpak install -y --noninteractive flathub org.freedesktop.Platform/x86_64/24.08
        fi

        # Install Alderon Games Launcher from local flatpak file
        FLATPAK_FILE="${./flatpaks/AlderonGamesLauncher-1.3.4.flatpak}"
        FLATPAK_ID="com.alderongames.launcher"

        # Check if flatpak is already installed
        if ! ${pkgs.flatpak}/bin/flatpak list --app | grep -q "$FLATPAK_ID"; then
          echo "Installing Alderon Games Launcher..."
          ${pkgs.flatpak}/bin/flatpak install -y --noninteractive "$FLATPAK_FILE"
        else
          echo "Alderon Games Launcher already installed"
        fi
      '';
      deps = [ ];
    };
  };
}
