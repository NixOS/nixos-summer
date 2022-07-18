{
  description = "Summer of Nix website";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ overlay ]; });
      inherit (builtins) readFile baseNameOf dirOf concatStringsSep elemAt;

      overlay = final: prev: {
        nixos-summer = prev.stdenv.mkDerivation {
          name = "nixos-summer";

          nativeBuildInputs = with prev; [
            imagemagick
            zola
          ];

          src = self;

          buildPhase = ''
            runHook preBuild
            zola build

            convert \
              -resize 16x16 \
              -background none \
              -gravity center \
              -extent 16x16 \
              static/images/logo.png \
              public/favicon.png

            convert \
              -resize x16 \
              -gravity center \
              -crop 16x16+0+0 \
              -flatten \
              -colors 256 \
              -background transparent \
              public/favicon.png \
              public/favicon.ico
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -r public $out
            runHook postInstall
          '';
        };
      };
    in
    {
      packages = forAllSystems (system: rec {
        inherit (nixpkgsFor.${system}) nixos-summer;
        default = nixos-summer;
      });
    };
}
