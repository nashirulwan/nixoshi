{ config, lib, pkgs, ... }:

{
  # Polkit for privilege escalation dialogs
  security.polkit.enable = true;
  
  # SSH agent for GitHub authentication
  programs.ssh.startAgent = true;
}
