{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    
    settings = {
      # User information
      user = {
        name = "nashiru";
        email = "nashirulwan@users.noreply.github.com";
      };
      
      # Git configuration
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
      core = {
        editor = "nvim";
      };
      
      # Signing format (legacy default untuk stateVersion < 25.05)
      signing.format = "openpgp";
      
      # Git aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "log --graph --oneline --decorate --all";
      };
    };
  };
}
