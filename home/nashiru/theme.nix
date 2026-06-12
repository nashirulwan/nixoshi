{ config, pkgs, ... }:

let
  # kora bagus tapi coverage app icon-nya sedikit (Inherits=breeze,hicolor),
  # jadi banyak app tampil blank di launcher Noctalia. Patch index.theme-nya
  # supaya fallback ke Papirus-Dark untuk icon yang tidak ada di kora.
  # Hasilnya: tampilan kora + coverage penuh Papirus. (Papirus-Dark harus
  # ikut terpasang di home.packages agar fallback-nya ketemu.)
  koraWithFallback = pkgs.kora-icon-theme.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      for t in kora kora-light kora-light-panel kora-pgrey; do
        idx="$out/share/icons/$t/index.theme"
        if [ -f "$idx" ]; then
          ${pkgs.gnused}/bin/sed -i \
            's/^Inherits=.*/Inherits=Papirus-Dark,Papirus,breeze,hicolor/' "$idx"
        fi
      done
    '';
  });

  # Tingkat transparansi background window app GTK.
  # 1.0 = solid, makin kecil makin tembus. Disamakan kira-kira dengan kitty (0.94).
  # Turunkan (mis. 0.80) kalau mau lebih tembus. MURNI opacity, tanpa blur.
  gtkOpacity = "0.85";

  # @import harus jadi baris pertama (aturan CSS), baru override di bawahnya.
  gtkTranslucency = ''
    @import url("noctalia.css");

    /* 1) Background window jadi translucent (tembus ke wallpaper/window belakang). */
    window,
    window.background,
    window.csd,
    .background {
      background-color: alpha(@window_bg_color, ${gtkOpacity});
    }

    /* 2) libadwaita/GTK4 menggambar konten (daftar file, sidebar, headerbar)
       dengan warna OPAQUE di atas window, jadi window-nya ketutup dan kelihatan
       solid. Paksa permukaan-permukaan ini transparan supaya alpha window di
       atas benar-benar kelihatan. Popover/menu sengaja TIDAK ditransparankan
       biar tetap kebaca. */
    .view,
    list,
    listview,
    columnview,
    gridview,
    .navigation-sidebar,
    .sidebar-pane,
    .content-pane,
    headerbar,
    .titlebar,
    scrolledwindow,
    stack {
      background-color: transparent;
    }
  '';
in
{
  home.packages = with pkgs; [
    adw-gtk3
    koraWithFallback      # kora (sudah di-patch fallback ke Papirus)
    papirus-icon-theme    # sumber fallback icon untuk app yang tidak ada di kora
  ];

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "kora";
      package = koraWithFallback;
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
    # JANGAN set gtk4.theme: itu membuat Home Manager menambahkan @import tema
    # adw-gtk3 di AKHIR gtk-4.0/gtk.css, sesudah override translucency kita,
    # sehingga background solid adw-gtk3 menimpa alpha kita. App GTK4/libadwaita
    # tetap dapat warna dari noctalia.css (diimport di awal gtkTranslucency).
    gtk4.theme = null;  # adopt new default, silences stateVersion warning
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  xdg.configFile = {
    "gtk-3.0/gtk.css" = {
      force = true;
      text = gtkTranslucency;
    };
    "gtk-4.0/gtk.css" = {
      force = true;
      text = gtkTranslucency;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
