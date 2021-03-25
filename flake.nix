{
  description = "A very basic flake";

  inputs.nixpkgs = { url = "nixpkgs/nixos-unstable"; };
  inputs.nixos-common-styles = { url = "github:NixOS/nixos-common-styles"; };

  outputs =
    { self
    , nixpkgs
    , nixos-common-styles
    }:
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
        pages =
          [
            {
              path = "index.html";
            }
            {
              path = "folder/index.html";
            }
          ];
        mkPage =
          { path
          , title ? null
          , body ? null
          }:
            let
              titleFinal =
                if title == null
                then "Summer of Nix"
                else "Summer of Nix - ${title}";
              bodyFinal =
                if body == null
                then builtins.readFile (self + "/" + path)
                else body;
              mkHeaderLink =
                { href
                , title
                , class ? ""
                }:
                  ''
                    <li class="${class}">
                      <a href="${href}">${title}</a>
                    </li>
                  '';
            in
              pkgs.writeText "${builtins.baseNameOf path}"
                ''
                  <!doctype html>
                  <html lang="en" class="without-js">
                  <head>
                    <title>${titleFinal}</title>
                    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                    <meta http-equiv="X-UA-Compatible" content="IE=Edge" />
                    <meta name="viewport" content="width=device-width, minimum-scale=1.0, initial-scale=1.0" />
                    <link rel="preconnect" href="https://fonts.gstatic.com">
                    <link rel="stylesheet" href="/styles/index.css" type="text/css" />
                    <link rel="shortcut icon" type="image/png" href="/favicon.png" />
                    <script>
                      var html = document.documentElement;
                      html.className = html.className.replace("without-js", "with-js");
                    </script>
                  </head>
                  <body>
                    <header>
                      <div>
                        <h1><a href="/">Summer of Nix</a></h1>
                        <!-- ???! go read `navbar.less` and `nixos-site.js`, it's all fine I swear. -->
                        <nav style="display: none;">
                          <ul>
                            ${mkHeaderLink { href = "https://nixos.org"; title = "nixos.org"; }}
                          </ul>
                        </nav>
                      </div>
                    </header>
                    <main>
                      ${bodyFinal}
                    </main>
                    <footer>
                      <div>
                        <div class="upper">
                          <section>
                            <h4>The project</h4>
                            <ul>
                              <li><a href="https://status.nixos.org/">Channel Status</a></li>
                              <li><a href="https://search.nixos.org/packages">Packages search</a></li>
                              <li><a href="https://search.nixos.org/options">Options search</a></li>
                              <li><a href="/community/teams/security.html">Security</a></li>
                            </ul>
                          </section>
                          <section>
                            <h4>Get in Touch</h4>
                            <ul>
                              <li><a href="https://discourse.nixos.org/">Forum</a></li>
                              <li><a href="https://webchat.freenode.net/#nixos">Chat</a></li>
                              <li><a href="/community/commercial-support.html">Commercial support</a></li>
                            </ul>
                          </section>
                          <section>
                            <h4>Contribute</h4>
                            <ul>
                              <li><a href="/guides/contributing.html">Contributing Guide</a></li>
                              <li><a href="/donate.html">Donate</a></li>
                            </ul>
                          </section>
                          <section>
                            <h4>Stay up to date</h4>
                            <ul>
                              <li><a href="/blog/index.html">Blog</a></li>
                              <li><a href="https://weekly.nixos.org/">Newsletter</a></li>
                            </ul>
                          </section>
                        </div>
                        <hr />
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

        buildPage = page:
          ''
            echo " -> /${page.path}"
            mkdir -p ${builtins.dirOf page.path}
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
              mkdir -p ./output
              pushd ./output
              echo "Generating pages:"
              ${builtins.concatStringsSep "\n" (builtins.map buildPage pages)}
              popd 

              mkdir -p ./output/styles
              rm -f styles/common-styles
              ln -s ${nixos-common-styles.packages."${system}".commonStyles} styles/common-styles
              echo "Generating styles:"
              echo " -> /styles/index.css"
              lessc --verbose \
                --source-map=styles/index.css.map \
                styles/index.less \
                ./output/styles/index.css
              mkdir -p ./output/styles/fonts
              for font in styles/common-styles/fonts/*.ttf; do
                echo " -> /styles/fonts/`basename $font`"
                cp $font ./output/styles/fonts/
              done
              mkdir -p ./output/js
              for jsscript in js/*.js; do
                echo " -> /js/`basename $jsscript`"
                cp $jsscript ./output/js/
              done
              echo " -> /favicon.png"
              convert \
                -resize 16x16 \
                -background none \
                -gravity center \
                -extent 16x16 \
                images/logo.png \
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
            pythonEnv = pkgs.python3.buildEnv.override {
              extraLibs = dependencies;
            };
          in
            pkgs.writeShellScriptBin name ''exec "${pythonEnv}/bin/python" "${toString ./.}/scripts/${name}.py" "$@"'';
      in
        {
          packages."${system}" = {
            nixos-summer = mkWebsite {};
            nixos-summer-serve = mkPyScript (with pkgs.python3Packages; [ click livereload ]) "serve";
          };
          defaultPackage."${system}" = self.packages."${system}".nixos-summer;
          devPackage."${system}" = mkWebsite { shell = true; };
        };
}
