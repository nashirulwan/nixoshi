{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    adw-gtk3
    papirus-icon-theme
  ];

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = config.home.pointerCursor.name;
      package = config.home.pointerCursor.package;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.theme = config.gtk.theme;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  xdg.configFile = {
    "gtk-3.0/gtk.css" = {
      force = true;
      text = ''
        @import url("noctalia.css");
      '';
    };
    "gtk-4.0/gtk.css" = {
      force = true;
      text = ''
        @import url("noctalia.css");
      '';
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
