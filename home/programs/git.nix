{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
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
      
      # Signing (off by default, enable when GPG key is set up)
      signing = {
        format = "openpgp";
        signByDefault = false;
      };
      
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
