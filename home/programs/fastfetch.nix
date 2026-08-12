{ ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "auto";
        padding = {
          top = 1;
          right = 2;
        };
      };
      display = {
        separator = "  ";
      };
      modules = [
        "title"
        "separator"
        { type = "os"; key = "OS"; }
        { type = "kernel"; key = "Kernel"; }
        { type = "uptime"; key = "Uptime"; }
        { type = "packages"; key = "Packages"; }
        { type = "shell"; key = "Shell"; }
        { type = "wm"; key = "WM"; }
        { type = "terminal"; key = "Terminal"; }
        "break"
        { type = "cpu"; key = "CPU"; }
        { type = "gpu"; key = "GPU"; }
        { type = "memory"; key = "Memory"; }
        { type = "disk"; key = "Disk"; }
        "break"
        { type = "colors"; symbol = "circle"; }
      ];
    };
  };
}
