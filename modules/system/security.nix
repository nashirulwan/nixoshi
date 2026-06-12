{ config, lib, pkgs, ... }:

{
  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;

  # SSH agent for GitHub authentication
  programs.ssh.startAgent = true;
  services.openssh.enable = true;

  # Allow the browser WebHID configurator to access SayoDevice O3C v1.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", ATTRS{idProduct}=="0009", MODE="0660", GROUP="users", TAG+="uaccess"
  '';
}
