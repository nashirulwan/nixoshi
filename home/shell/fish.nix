{ lib, privateRoot ? null, ... }:

let
  commonAliases = {
    # Quick navigation
    ll = "ls -lah";
    la = "ls -A";

    # Git shortcuts
    gs = "git status";
    ga = "git add";
    gc = "git commit";
    gp = "git push";

    # Editor
    v = "nvim";
  };

  deploymentAliases = lib.optionalAttrs (privateRoot != null) (
    let
      root = lib.escapeShellArg (toString privateRoot);
    in
    {
      rebuild = "sudo nixos-rebuild switch --flake ${root}";
      rebuild-test = "sudo nixos-rebuild test --flake ${root}";
      update = "cd ${root} && nix flake update && rebuild";
      dotfiles-status = "${root}/scripts/dotfiles-status.sh";
    }
  );
in
{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;

    shellAliases = commonAliases // deploymentAliases;

    # User-specific shell initialization
    shellInit = ''
      # Tide prompt configuration
      set -g tide_prompt_icon_connection ' '
      set -g tide_left_prompt_items pwd git
      set -g tide_right_prompt_items status cmd_duration context time
      set -g tide_cmd_duration_threshold 3000

      # Custom greeting
      function fish_greeting
        echo "Today is" (date +"%A, %B %d, %Y")
      end
    '';
  };
}
