This is source code for [summer.nixos.org](https://summer.nixos.org) website.


## Contribute

To contribute please send a Pull Request. A **preview link** is going to be
generated and added as a comment once build of the website finishes.

To develop on the website **locally** you have multiple possibilities.

```console
# If you use direnv
$ make serve
# If you don’t use direnv but have flake-enabled Nix
$ nix develop -c make serve
# If you don’t have direnv or flake-enabled Nix
$ nix-shell --run "make serve"
```

The site will automatically get rebuilt if you change its content.
However, please note that changes to the style (less) or the config are not affected by this,
so after you update them,
you need to restart the server.

The server will be listening on **`http://127.0.0.1:1111`** by default,
though this can change if that port is already in use.

Happy hacking!


## License

The content of the website is licensed under the [Creative Commons Attribution
Share Alike 4.0 International](LICENSE.txt) license.

