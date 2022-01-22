{
  description = "A very basic flake";

  inputs.nixpkgs = { url = "nixpkgs/nixos-unstable"; };
  inputs.nixos-common-styles = { url = "github:NixOS/nixos-common-styles"; };

  outputs =
    { self, nixpkgs, nixos-common-styles }:
    let
      inherit (builtins) readFile baseNameOf dirOf concatStringsSep;
      inherit (import ./utils.nix { inherit pkgs; }) mkPage;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      indexPage = mkPage {
        path = ./src/index.html;
        title = "Summer of Nix";
        body = readFile ./src/index.html;
      };

      blogPage = mkPage {
        path = ./src/blog.html;
        title = "Summer of Nix";
        body = readFile ./src/blog.html;
      };

      mkWebsite = { shell ? false }:
        pkgs.stdenv.mkDerivation {
          name = "nixos-summer-${self.lastModifiedDate}";
          src = self;
          preferLocalBuild = true;
          enableParallelBuilding = true;
          buildInputs = with pkgs; [
            imagemagick
            nodePackages.less
          ];
          buildPhase = ''
            function log() {  printf '\033[31;1m=>\033[m %s\n' "$@"; }

            log "Make folder structure"; {
                mkdir -p ./output/{styles/fonts,js}
            }

            log "Building pages"; {
                pushd ./output
                ln -s ${indexPage} index.html
                ln -s ${blogPage} blog.html
                popd
            }

            log "Generating styles"; {
                ln -sf ${nixos-common-styles.packages."${system}".commonStyles} src/styles/common-styles
                lessc --verbose \
                  --source-map=styles/index.css.map \
                  src/styles/index.less \
                  ./output/styles/index.css
            }

            log "Copying fonts and js to output"; {
                cp -R src/images ./output/images
                cp -R src/styles/common-styles/fonts/*.ttf ./output/styles/fonts/
                cp -R src/js/* ./output/js/
            }

            log "Generating favicon's"; {
                convert \
                  -resize 16x16 \
                  -background none \
                  -gravity center \
                  -extent 16x16 \
                  src/images/logo.png \
                  ./output/favicon.png

                convert \
                  -resize x16 \
                  -gravity center \
                  -crop 16x16+0+0 \
                  -flatten \
                  -colors 256 \
                  -background transparent \
                  ./output/favicon.png \
                  ./output/favicon.ico
            }
          '';
          installPhase = ''
            mkdir -p $out
            cp -R ./output/* $out/
          '';
          shellHook = ''
            rm -f styles/common-styles
            ln -s ${nixos-common-styles.packages."${system}".commonStyles} styles/common-styles
          '';
        };
      mkPyScript = dependencies: name:
        let
          pythonEnv = pkgs.python3.buildEnv.override { extraLibs = dependencies; };
        in
        pkgs.writeShellScriptBin name ''exec "${pythonEnv}/bin/python" "${toString ./.}/scripts/${name}.py" "$@"'';
    in
    {
      packages."${system}" = {
        nixos-summer = mkWebsite { };
        nixos-summer-serve = mkPyScript (with pkgs.python3Packages; [ click livereload ]) "serve";
      };
      defaultPackage."${system}" = self.packages."${system}".nixos-summer;
      devPackage."${system}" = mkWebsite { shell = true; };
    };
}
