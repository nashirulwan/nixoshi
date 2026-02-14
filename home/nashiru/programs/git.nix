{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    
    # User information
    userName = "Nashiru";
    userEmail = "nashirulwan@users.noreply.github.com";
    
    # Git configuration
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
      core = {
        editor = "nvim";
      };
    };
    
    # Git aliases
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "log --graph --oneline --decorate --all";
    };
  };
}
