{
  description = "Ryan's Nix-Config";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Darwin hosts track nixpkgs-unstable, not nixos-unstable: the nixos-*
    # branches are gated on the NixOS jobset (kernel, bootloader, VM tests),
    # which says nothing about whether aarch64-darwin was built - so darwin
    # lands on revisions Hydra has not finished and compiles from source.
    # The converse is worse: pointing NixOS at a darwin branch leaves kernel
    # and bootloader unchecked. Keep each platform on the branch that gates
    # what it actually boots.
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    ## NixOS ##

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    ## Darwin ##

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.flake-compat.follows = "";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Theming ##

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen = {
      url = "github:/InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Global catppuccin theme
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Gaming Packages ##

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Misc Packages ##

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Plasma ##
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      imports = [
        ./modules/flake/overlays.nix
        ./modules/flake/nixos.nix
        ./modules/flake/darwin.nix
        ./modules/flake/packages.nix
        ./modules/flake/devshell.nix
      ];
    };
}
