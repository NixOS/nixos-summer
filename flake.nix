{
  description = "Summer of Nix website";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  inputs.nixos-common-styles.url = "github:NixOS/nixos-common-styles";
  inputs.nixos-common-styles.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, nixos-common-styles }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (system: rec {
        nixos-summer-website = nixpkgsFor.${system}.stdenvNoCC.mkDerivation {
          name = "nixos-summer-website";
          src = self;
          nativeBuildInputs = with nixpkgsFor.${system}; [ zola imagemagick lessc ];
          configurePhase = ''
            ln -s ${nixos-common-styles.packages.${system}.commonStyles} less/nixos-common-styles
          '';
          installPhase = "cp -r public $out";
        };
        default = nixos-summer-website;
      });

      devShells = forAllSystems (system: {
        default = nixpkgsFor.${system}.mkShellNoCC {
          packages = with nixpkgsFor.${system}; [ imagemagick lessc zola ];
          shellHook = ''
            ln -sfT ${nixos-common-styles.packages.${system}.commonStyles} less/nixos-common-styles
          '';
        };
      });
    };
}
