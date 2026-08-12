{
  description = "Reusable NixOS and Home Manager rice modules";

  inputs = {
    # Main package repository
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Zen Browser
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia shell for Niri.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # MangoWC: Wayland compositor (dwl-based). Dipasang berdampingan dengan niri.
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Older mpv branch for Feishin compatibility.
    nixpkgs-mpv-compat.url = "github:nixos/nixpkgs/nixos-23.05";

    # Codex Desktop Linux
    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";
  };

  outputs = inputs@{ self, ... }: {
    nixosModules.default = {
      _module.args.inputs = inputs;
      imports = [
        inputs.mango.nixosModules.mango
        ./modules/public-default.nix
      ];
    };

    homeManagerModules.default = {
      _module.args = {
        inherit inputs;
        nixoshiSettingsFile = null;
        privateRoot = null;
      };
      imports = [
        inputs.noctalia.homeModules.default
        inputs.mango.hmModules.mango
        ./home
      ];
    };
  };
}
