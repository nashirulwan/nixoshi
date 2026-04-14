{ config, lib, pkgs, ... }:

{
  # Enable Ollama service
  services.ollama = {
    enable = true;
  };
}
