{ pkgs }: {
  mkPage = { path, title, body }:
    pkgs.writeText "${builtins.baseNameOf path}"
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
