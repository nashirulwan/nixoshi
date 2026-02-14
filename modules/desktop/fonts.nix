{ config, lib, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      # Nerd Fonts - Programming fonts with icons
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.symbols-only
      
      # Modern UI fonts
      inter
      roboto
      roboto-slab
      
      # International fonts
      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      
      # Icon fonts for UI elements
      font-awesome
      material-design-icons
    ];
    
    # Font configuration priorities
    fontconfig = {
      defaultFonts = {
        serif = [ "Roboto" "Noto Fonts Emoji" ];
        sansSerif = [ "Inter" "Roboto" "Noto Fonts Emoji" ];
        monospace = [ "JetBrainsMono Nerd Font" "Noto Fonts Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
