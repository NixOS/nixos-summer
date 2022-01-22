{
  description = "Summer of Nix website";

  inputs.nixpkgs = { url = "nixpkgs/master"; };
  inputs.nixos-common-styles = {
    url = "github:DieracDelta/nixos-common-styles/multi-arch";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, nixos-common-styles }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ overlay ]; });
      inherit (builtins) readFile baseNameOf dirOf concatStringsSep elemAt;


      overlay = final: prev:
        let
          inherit (import ./utils.nix { pkgs = prev.pkgs; }) mkPage mkBlogPage mkBlogsIndexPage;
          articles = (import ./blog);
        in
        {
          indexPage = mkPage {
            title = "Summer of Nix";
            body = readFile ./src/index.html;
          };

          blogsIndexPage = mkBlogsIndexPage articles;

          mkWebsite = { shell ? false }:
            prev.pkgs.stdenv.mkDerivation {
              name = "nixos-summer-${self.lastModifiedDate}";
              src = self;
              preferLocalBuild = true;
              enableParallelBuilding = true;
              buildInputs = with prev.pkgs; [
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
                    ln -s ${final.indexPage} index.html
                    ln -s ${final.blogsIndexPage} blog.html
                    popd
                }

                log "Generating styles"; {
                  ln -sf ${nixos-common-styles.packages."${final.system}".commonStyles} src/styles/common-styles

                  lessc --verbose \
                    --math=always --source-map=$(pwd)/styles/index.css.map \
                    src/styles/index.less \
                    ./output/styles/index.css
                  cp $(pwd)/styles/index.css.map $(pwd)/output/styles/index.css.map
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
                ln -s ${nixos-common-styles.packages."${final.system}".commonStyles} styles/common-styles
              '';
            };
          mkPyScript = dependencies: name:
            let
              pythonEnv = prev.pkgs.python3.buildEnv.override { extraLibs = dependencies; };
            in
            prev.pkgs.writeShellScriptBin name ''exec "${pythonEnv}/bin/python" "${toString ./.}/scripts/${name}.py" "$@"'';

        };
    in
    {
      packages = forAllSystems (system:
        let inherit (nixpkgsFor.${system}) mkWebsite mkPyScript python3Packages; in
        {
          nixos-summer = mkWebsite { };
          nixos-summer-serve = mkPyScript (with python3Packages; [ click livereload ]) "serve";
          nixos-summer-dev = mkWebsite { shell = true; };

        });
      defaultPackage = forAllSystems (system: self.packages.${system}.nixos-summer);
      devPackage = forAllSystems (system: self.packages.${system}.nixos-summer-dev);

    };
}
