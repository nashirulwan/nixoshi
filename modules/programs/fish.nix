{ config, lib, pkgs, ... }:

{
  # Enable Fish shell system-wide
  programs.fish = {
    enable = true;
    
    # System-wide Fish initialization
    # Note: User-specific config will be in home-manager
    interactiveShellInit = ''
      set fish_greeting
      fish_add_path ~/.npm-global/bin
    '';
  };
  
  # Fish plugins and tools
  environment.systemPackages = with pkgs; [
    fzf                      # Fuzzy finder (dependency)
    fishPlugins.fzf-fish     # Fuzzy search for Fish
    fishPlugins.tide         # Beautiful prompt theme
    fishPlugins.forgit       # Interactive git commands
    fishPlugins.grc          # Colorize command output
    grc                      # GRC dependency
    fishPlugins.autopair     # Auto-close brackets/quotes
    fishPlugins.puffer       # Text expansion
  ];
}
