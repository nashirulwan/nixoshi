{
  description = "Nashiru's NixOS Configuration - Modular Edition";

  inputs = {
    # Main package repository
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager for user dotfiles
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
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
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.nixoshi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Host configuration
        ./hosts/nixoshi
        
        # Home Manager integration
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.nashiru = import ./home/nashiru;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  };
}
