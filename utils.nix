{ pkgs }: rec {

  runCommand = name: args: script:
    pkgs.runCommand name
      (args // {
        runLocal = true;
        preferLocalBuild = true;
        enableParallelBuilding = true;
      })
      script;

  mkBlogSummarySection = it: ''
    <section class="info">
      <div>
        <a href="#abc"><h2>${it.title}</h2></a>
        <p>${it.description}</p>
      </div>
    </section>
  '';

  mkBlogsIndexPage = articles: mkPage {
    title = "Summer of Nix - Blogs";
    body = ''
      <section class="hero">
        <div>
          <div class="blurb">
            <h1>The Summer of Nix Blog</h1>
            <p>A series of blog posts detailing the experiences of the Summer of Nix participants.</p>
            <div class="button-tray">
              <a class="button -primary" href="/#update-2021-06-02">Applications are closed</a>
              <a class="button" href="/#about">Learn more</a>
              <a class="button" href="/">Home</a>
            </div>
          </div>
        </div>
      </section>

      ${builtins.concatStringsSep "\n" (map mkBlogSummarySection articles)}
    '';
  };

  mkBlogPage = { title, mdPath }:
    let
      path = runCommand "markdown2html"
        { buildInputs = [ pkgs.pandoc ]; }
        ''pandoc -- ${mdPath} >> $out'';
    in
    mkPage {
      inherit title path;
      body = ''
        <section class="hero">
          <div>
            <div class="blurb">
              <h1>The Summer of Nix Blog</h1>
              <p>A series of blog posts detailing the experiences of the Summer of Nix participants.</p>
              <div >
                <a class="button -primary" href="#post">${title}</a>
              </div>
            </div>
          </div>
        </section>

        <section class="post" id="#post">
          ${builtins.readFile path}
        </section>
      '';
    };
  mkPage = { title, body }:
    pkgs.writeText (builtins.replaceStrings [ " " ] [ "-" ] title)
      ''
        <!doctype html>
        <html lang="en" class="without-js">
        <head>
          <title>${title}</title>
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
            ${body}
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
}
