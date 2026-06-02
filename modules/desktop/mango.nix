{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.mango.nixosModules.mango ];

  programs.mango.enable = true;

  environment.sessionVariables.GDK_BACKEND = "wayland";

  services.displayManager.defaultSession = lib.mkForce "mango";

  xdg.portal.wlr.settings.screencast = {
    output_name = "HDMI-A-1";
    chooser_type = "none";
    max_fps = 60;
  };
}
