{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;
    
    # User-specific shell aliases
    shellAliases = {
      # Quick navigation
      ll = "ls -lah";
      la = "ls -A";
      
      # NixOS shortcuts
      rebuild = "sudo nixos-rebuild switch --flake ~/nixoshi#nixoshi";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixoshi#nixoshi";
      update = "cd ~/nixoshi && sudo nix flake update && rebuild";
      
      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      
      # Editor
      v = "nvim";
    };
    
    # User-specific shell initialization
    shellInit = ''
      # Tide prompt configuration
      set -g tide_prompt_icon_connection ' '
      set -g tide_left_prompt_items pwd git
      set -g tide_right_prompt_items status cmd_duration context jobs time
      set -g tide_cmd_duration_threshold 3000
      
      # Custom greeting
      function fish_greeting
        echo "Welcome back, Nashiru! 🚀"
        echo "Today is" (date +"%A, %B %d, %Y")
      end
    '';
  };
}
