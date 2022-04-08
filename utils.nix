{ pkgs }: rec {

  runCommand = name: args: script:
    pkgs.runCommand name
      (args // {
        runLocal = true;
        preferLocalBuild = true;
        enableParallelBuilding = true;
      })
      script;

  # like linkfarm but preserve names
  linkFarmCustom = name: entries: pkgs.runCommand name { preferLocalBuild = true; allowSubstitutes = false; }
    ''mkdir -p $out
      cd $out
      ${pkgs.lib.concatMapStrings (x: ''
          ln -s ${pkgs.lib.escapeShellArg x.path} ${pkgs.lib.escapeShellArg x.name}
      '') entries}
    '';

  mergeBlogPages = blogs: titles:
    # FIXME point free?
    let
      titlesNoWhitespace = map mkBlogTitle titles;
      zipped = pkgs.lib.zipListsWith (blog: title: { name = title; path = blog; }) blogs titlesNoWhitespace;
    in
    linkFarmCustom "blogs" zipped;

  mkBlogTitle = title: (pkgs.lib.stringAsChars (x: if x == " " then "_" else x) title) + ".html";

  mkBlogSummarySection = it: ''
    <section class="info">
      <div>
        <a href="./${mkBlogTitle it.title}"><h2>${it.title}</h2></a>
        <p>${it.description}</p>
      </div>
    </section>
  '';

  applyButton = { class = "-primary"; href = "/#update-2022-04-04"; title = "Apply"; };
  learnMoreButton = { href = "/#about"; title = "Learn more"; };
  homeButton = { href = "/"; title = "Home"; };

  mkHeader = { title, description, buttons ? [ applyButton learnMoreButton homeButton ] }: ''
    <section class="hero">
      <div>
        <div class="blurb">
          <h1>${title}</h1>
          <p>${description}</p>
          <div class="button-tray">
            ${builtins.concatStringsSep "\n" (map (it: ''<a class="button ${it.class or ""}" href="${it.href}">${it.title}</a>'') buttons)}
          </div>
        </div>
      </div>
    </section>
  '';

  mkBlogsIndexPage = articles: mkPage {
    title = "Summer of Nix - Blogs";
    header = mkHeader {
      title = "The Summer of Nix Blog";
      description = "A series of blog posts detailing the experiences of the Summer of Nix participants.";
    };
    body = map mkBlogSummarySection articles;
  };
  mkSponsorsSection = it: "";
  mkSponsorsPage = sponsors: mkPage {
    title = "Summer of Nix - Sponsors";
    header = mkHeader {
      title = "The Summer of Nix Sponsors";
      description = "People who are making the world of Nix a better place.";
    };
    body = map mkSponsorsSection sponsors;
  };

  mkBlogPage = { title, mdPath, description }:
    let
      path = runCommand "markdown2html"
        { buildInputs = [ pkgs.pandoc ]; }
        ''pandoc -- ${mdPath} >> $out'';
    in
    mkPage {
      inherit title;
      header = mkHeader {
        title = title;
        description = "A series of blog posts detailing the experiences of the Summer of Nix participants.";
      };
      body = ''
        <section class="post" id="#post">
          ${builtins.readFile path}
        </section>
      '';
    };
  mkPage = { title, header ? "", body }:
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
            ${header}
            ${toString body}
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
