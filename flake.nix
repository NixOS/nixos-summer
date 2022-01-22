{
  description = "A very basic flake";

  inputs.nixpkgs = { url = "nixpkgs/nixos-unstable"; };
  inputs.nixos-common-styles = { url = "github:NixOS/nixos-common-styles"; };

  outputs =
    { self, nixpkgs, nixos-common-styles }:
    let
      inherit (builtins) readFile baseNameOf dirOf concatStringsSep;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pages =
        [
          { path = "index.html"; }
          { path = "blog.html"; }
        ];
      mkPage =
        { path, title ? null, body ? null }:
        let
          titleFinal =
            if title == null
            then "Summer of Nix"
            else "Summer of Nix - ${title}";
          bodyFinal =
            if body == null
            then readFile (self + "/" + path)
            else body;
          mkHeaderLink = { href, title, class ? "" }: ''
            <li class="${class}">
              <a href="${href}">${title}</a>
            </li>
          '';
        in
        pkgs.writeText "${baseNameOf path}"
          ''
            <!doctype html>
            <html lang="en" class="without-js">
            <head>
              <title>${titleFinal}</title>
              <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
              <meta http-equiv="X-UA-Compatible" content="IE=Edge" />
              <meta name="viewport" content="width=device-width, minimum-scale=1.0, initial-scale=1.0" />
              <link rel="stylesheet" href="/styles/index.css" type="text/css" />
              <link rel="shortcut icon" type="image/png" href="/favicon.png" />
              <script>
                var html = document.documentElement;
                html.className = html.className.replace("without-js", "with-js");
              </script>
            </head>
            <body>
              <main>
                ${bodyFinal}
              </main>
              <footer>
                <div>
                  <div class="lower">
                    <section class="footer-copyright">
                      <h4>NixOS</h4>
                      <div>
                        <span>
                          Copyright © 2021 NixOS contributors
                        </span>
                        <a href="https://github.com/NixOS/nixos-homepage/blob/master/LICENSES/CC-BY-SA-4.0.txt">
                          <abbr title="Creative Commons Attribution Share Alike 4.0 International">
                            CC-BY-SA-4.0
                          </abbr>
                        </a>
                      </div>
                    </section>
                    <section class="footer-social">
                      <h4>Connect with us</h4>
                      <ul>
                        <li class="social-icon -twitter"><a href="https://twitter.com/nixos_org">Twitter</a></li>
                        <li class="social-icon -youtube"><a
                            href="https://www.youtube.com/channel/UC3vIimi9q4AT8EgxYp_dWIw">Youtube</a></li>
                        <li class="social-icon -github"><a href="https://github.com/NixOS">GitHub</a></li>
                      </ul>
                    </section>
                  </div>
                </div>
              </footer>
              <script type="text/javascript" src="/js/jquery.min.js"></script>
              <script type="text/javascript" src="/js/index.js"></script>
            </body>
            </html>
          '';

      buildPage = page: ''
        echo " -> /${page.path}"
        mkdir -p ${dirOf page.path}
        ln -s ${mkPage page} ${page.path}
      '';
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
            function log() { echo $@; }

            mkdir -p ./output
            pushd ./output
            echo "Generating pages:"
            ${concatStringsSep "\n" (map buildPage pages)}
            popd

            cp -R src/images ./output/images
            mkdir -p ./output/styles
            rm -f src/styles/common-styles
            ln -s ${nixos-common-styles.packages."${system}".commonStyles} src/styles/common-styles

            echo "Generating styles:"
            echo " -> /styles/index.css"

            lessc --verbose \
              --source-map=styles/index.css.map \
              src/styles/index.less \
              ./output/styles/index.css

            mkdir -p ./output/{styles/fonts,js}

            for font in src/styles/common-styles/fonts/*.ttf; do
              echo " -> /styles/fonts/`basename $font`"
              cp $font ./output/styles/fonts/
            done


            for jsscript in src/js/*.js; do
              echo " -> /js/`basename $jsscript`"
              cp $jsscript ./output/js/
            done

            echo " -> /favicon.png"
            convert \
              -resize 16x16 \
              -background none \
              -gravity center \
              -extent 16x16 \
              src/images/logo.png \
              ./output/favicon.png
            echo " -> /favicon.ico"
            convert \
              -resize x16 \
              -gravity center \
              -crop 16x16+0+0 \
              -flatten \
              -colors 256 \
              -background transparent \
              ./output/favicon.png \
              ./output/favicon.ico
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
