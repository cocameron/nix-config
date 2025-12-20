{ config, pkgs, ... }:
let
  theme = import ../../common/everforest-theme.nix;
in
{
  xdg.configFile."ghostty/config".text = ''
    # Everforest Dark theme for Ghostty

    # Font configuration
    font-family = "JetBrainsMono Nerd Font"
    font-size = 14

    # Theme - Everforest Dark
    background = ${theme.colors.bg0}
    foreground = ${theme.colors.fg}

    # Cursor
    cursor-color = ${theme.colors.fg}
    cursor-text = ${theme.colors.bg0}

    # Selection
    selection-background = ${theme.colors.bg_visual}
    selection-foreground = ${theme.colors.fg}

    # ANSI Colors
    palette = 0=${theme.ansi.black}
    palette = 1=${theme.ansi.red}
    palette = 2=${theme.ansi.green}
    palette = 3=${theme.ansi.yellow}
    palette = 4=${theme.ansi.blue}
    palette = 5=${theme.ansi.magenta}
    palette = 6=${theme.ansi.cyan}
    palette = 7=${theme.ansi.white}

    # Bright ANSI Colors
    palette = 8=${theme.ansi.bright_black}
    palette = 9=${theme.ansi.bright_red}
    palette = 10=${theme.ansi.bright_green}
    palette = 11=${theme.ansi.bright_yellow}
    palette = 12=${theme.ansi.bright_blue}
    palette = 13=${theme.ansi.bright_magenta}
    palette = 14=${theme.ansi.bright_cyan}
    palette = 15=${theme.ansi.bright_white}

    # Window configuration
    window-padding-x = 10
    window-padding-y = 10
    window-theme = dark

    # macOS specific
    macos-option-as-alt = true
    macos-titlebar-style = tabs
    macos-icon = custom-style
    macos-icon-ghost-color = ${theme.colors.fg}
    macos-icon-screen-color = ${theme.colors.bg0}
  '';
}
