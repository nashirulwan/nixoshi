{ config, pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = false; # We use custom wrapper for persistence
    settings = {
      manager = {
        show_hidden = true;
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "none";
        show_symlink = true;
      };
    };
  };

  # Zoxide - a smarter cd command, integrates well with Yazi
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Custom shell functions for Yazi persistence
  programs.fish.functions = {
    yazi = {
      body = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
          echo "$cwd" > ~/.cache/yazi_lastdir
        end
        rm -f -- "$tmp"
      '';
    };
    y = {
      body = ''
        set last_dir ""
        if test -f ~/.cache/yazi_lastdir
          set last_dir (cat ~/.cache/yazi_lastdir)
        end
        
        if test -d "$last_dir"
          yazi "$last_dir"
        else
          yazi
        end
      '';
    };
  };
}
