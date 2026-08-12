{
  description = "Minimal Home Manager consumer for the public rice module";

  inputs = {
    # This example lives inside the repository. Replace this with the public
    # GitHub flake URL when copying the example into another configuration.
    nixoshi.url = "path:..";

    nixpkgs.follows = "nixoshi/nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixoshi, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.demo = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nixoshi.homeManagerModules.default
          {
            home.username = "demo";
            home.homeDirectory = "/home/demo";
          }
        ];
      };
    };
}
