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
        <a href="./${mkBlogTitle it.title}"><h2>${it.date} ${it.title} - ${it.author} </h2></a>
        <p>${it.description}</p>
      </div>
    </section>
  '';

  applicationsClosedButton = { class = "-primary"; href = "/#update-2021-06-02"; title = "Applications are closed"; };
  learnMoreButton = { href = "/#about"; title = "Learn more"; };
  homeButton = { href = "/"; title = "Home"; };
  defaultButtons = [ applicationsClosedButton learnMoreButton homeButton ];

  mkHeader = { title, description, buttons ? defaultButtons, ... }: ''
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

  mkBlogHeader = { title, description, buttons ? defaultButtons, author, date, ... }: ''
    <section class="hero">
      <div>
        <div class="blurb">
          <h1>${title}</h1>
          <h4>${date} - ${author} </h4>
          <p>${description}</p>
          <div class="button-tray">
            ${toString (map (it: ''<a class="button ${it.class or ""}" href="${it.href}">${it.title}</a>'') buttons)}
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

  mkBlogPage = info@{ title, mdPath, description, author, date, ... }:
    let
      path = runCommand "markdown2html"
        { buildInputs = [ pkgs.pandoc ]; }
        ''pandoc -t html5 --no-highlight ${mdPath} >> $out'';
    in
    mkPage {
      header-extra =
        ''
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/themes/prism.min.css" integrity="sha512-tN7Ec6zAFaVSG3TpNAKtk4DOHNpSwKHxxrsiw4GHKESGPs5njn/0sMCUMl2svV4wo4BK/rCP7juYz+zx+l6oeQ==" crossorigin="anonymous" referrerpolicy="no-referrer" />
        <style>
          code { border: 0px !important;}
        </style>
        '';

      inherit title;
      header = mkBlogHeader (info // {
        description = "A series of blog posts detailing the experiences of the Summer of Nix participants.";
      });
      body = ''
          <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/components/prism-core.min.js" integrity="sha512-NC2WFBzw/SdbWrzG0C+sg3iv1OITcQKsUitDcYKfOp9vxe92zpNlRc5Ad3q81kAp8Ff/fDV8pZQxdCCeyFdgLw==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/components/prism-nix.min.js" integrity="sha512-kvMZ1NV1faCpNs9FZlhvnWQ1iiU93GalWptzmvYRJDXQCb+wK/dR9oB3hTRmTA7c2CeEbEfjGDMM3j+CVlhr6Q==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
          <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/autoloader/prism-autoloader.min.js" integrity="sha512-GP4x8UWxWyh4BMbyJGOGneiTbkrWEF5izsVJByzVLodP8CuJH/n936+yQDMJJrOPUHLgyPbLiGw2rXmdvGdXHA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
        <section class="post" id="#post">
          ${builtins.readFile path}
        </section>
      '';
    };
  mkPage = { title, header ? "", body, header-extra ? "" }:
    pkgs.writeText (builtins.replaceStrings [ " " ] [ "-" ] title)
      ''
        ${header-extra}
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
