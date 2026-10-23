{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default-linux";
  };

  outputs =
    {
      nixpkgs,
      self,
      systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = lib.genAttrs (import systems);
      loadPackages =
        callPackage:
        lib.filesystem.packagesFromDirectoryRecursive {
          inherit callPackage;
          directory = ./packages;
        };
    in
    {
      checks = self.packages;

      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      packages = eachSystem (system: loadPackages nixpkgs.legacyPackages.${system}.callPackage);

      overlays.default = final: prev: loadPackages final.callPackage;
    };
}
