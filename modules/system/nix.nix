{ config, lib, pkgs, ... }:

{
  # Nix cache configuration untuk mengurangi download
  nix.settings = {
    # Binary substituters - download dari cache, bukan build dari source
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];

    # Public keys untuk verifikasi cache
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9Fys945kSZg4nq0F6Q4VZis60pPkgR7Xc0T3Mz5Kc="
    ];

    # Optimasi build
    auto-optimise-store = true;  # Deduplicate files yang sama
    max-jobs = "auto";           # Pakai semua CPU core
    cores = 0;                   # 0 = unlimited cores untuk build
  };
}
