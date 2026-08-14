{ config, lib, pkgs, inputs, hyperhdrPreferredOutput ? null, ... }:

let
  hyperhdrOutputChooser = pkgs.writeShellScript "hyperhdr-output-chooser" ''
    ${lib.optionalString (hyperhdrPreferredOutput != null)
      "export HYPERHDR_PREFERRED_OUTPUT=${lib.escapeShellArg hyperhdrPreferredOutput}"}
    export PATH="${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:$PATH"
    export WLR_RANDR_CMD="${pkgs.wlr-randr}/bin/wlr-randr"
    exec ${pkgs.bash}/bin/bash ${./hyperhdr-output-chooser.sh}
  '';
in

{
  programs.mango.enable = true;

  environment.sessionVariables.GDK_BACKEND = "wayland";

  services.displayManager.defaultSession = lib.mkForce "mango";

  xdg.portal.wlr.settings.screencast = {
    chooser_type = "simple";
    chooser_cmd = "${hyperhdrOutputChooser}";
    max_fps = 60;
  };
}
