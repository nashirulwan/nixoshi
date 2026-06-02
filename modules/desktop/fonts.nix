{ config, lib, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      nerd-fonts.symbols-only

      inter
      roboto
      roboto-slab

      noto-fonts
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif

      font-awesome
      material-design-icons
    ];

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
