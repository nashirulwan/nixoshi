final: prev: {
  # xorg.libxcb has been renamed to libxcb
  xorg = prev.xorg // {
    libxcb = prev.libxcb;
  };

  # swww has been renamed to awww
  swww = prev.awww or prev.swww or null;
}
