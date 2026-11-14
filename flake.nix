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

      legacyPackages = eachSystem (
        system:
        nixpkgs.legacyPackages.${system}.extend (
          _: prev: {
            # https://github.com/Mic92/nix-update/issues/687
            nix-update = prev.nix-update.overridePythonAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace nix_update/options.py \
                  --replace-fail '"flake", "metadata"' '"flake", "archive"'
              '';
            });
          }
        )
      );

      overlays.default =
        final: prev:
        loadPackages (
          path: args:
          let
            name = baseNameOf (dirOf path);
            # Use the original package for self-overrides and final for other dependencies.
            scope = final // lib.optionalAttrs (builtins.hasAttr name prev) { ${name} = prev.${name}; };
          in
          lib.callPackageWith scope path args
        );

      packages = eachSystem (system: loadPackages self.legacyPackages.${system}.callPackage);
    };
}
