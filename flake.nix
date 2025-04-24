{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    unstableNixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # mac-app-util = {
    #  url = "github:hraban/mac-app-util";
    #  inputs.nixpkgs.url = "github:NixOS/nixpkgs?rev=a84b0a7c509bdbaafbe6fe6e947bdaa98acafb99";
    #};

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    quadlet-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nix-darwin,
      nixpkgs,
      unstableNixpkgs,

      ...
    }@inputs:
    let
      # Define pkgs-unstable once for Linux systems
      pkgs-unstable-linux = import inputs.unstableNixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    {
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-rfc-style;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      };

      darwinConfigurations."Colins-MacBook-Pro-3" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./mac-config.nix
        ];
      };

      nixosConfigurations = {
        nixos-wsl = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          system = "x86_64-linux";
          modules = [
            ./nixos-wsl-config.nix
          ];
        };

        nixlab = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            # Use the centrally defined unstable packages
            pkgs-unstable = pkgs-unstable-linux;
          };
          system = "x86_64-linux";
          modules = [
            ./nixlab-config.nix
          ];
        };

        greenix = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            # Use the centrally defined unstable packages
            pkgs-unstable = pkgs-unstable-linux;
          };
          system = "x86_64-linux";
          modules = [
            ./greenix-config.nix
          ];
        };
      };

    };
}
