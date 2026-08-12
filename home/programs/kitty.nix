{ ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    settings = {
      background_opacity = "0.85";
      confirm_os_window_close = 0;
      cursor_shape = "beam";
      enable_audio_bell = false;
      hide_window_decorations = "titlebar-only";
      remember_window_size = false;
      initial_window_width = 960;
      initial_window_height = 560;
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      window_padding_width = 8;
    };
    # Matugen colors pushed live by Noctalia.
    extraConfig = ''
      include themes/noctalia.conf

      # Middle mouse button often mis-triggers on trackpad; disable primary-selection paste.
      mouse_map middle release ungrabbed no_op
    '';
  };
}
