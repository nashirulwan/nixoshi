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

    # Local editable end-4 dotfiles source
    dotfiles = {
      url = "path:/home/nashiru/dots-hyprland";
      flake = false;
    };

    # end-4 dots-hyprland (community Nix flake wrapper)
    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dotfiles.follows = "dotfiles";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.nixoshi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Apply overlays
        { nixpkgs.overlays = [
          (import ./overlays/renames.nix)
        ]; }

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
