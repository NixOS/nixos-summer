This is source code for [summer.nixos.org](https://summer.nixos.org) website.


## Contribute

To contribute please send a Pull Request. A **preview link** is going to be
generated and added as a comment once build of the website finishes.

To develop on the website **locally** use the following commands.

```console
$ nix build ./#packages.x86_64-linux.nixos-summer-serve -o ./result-serve
$ ./result-serve/bin/serve
```

Last command will build the repository and **watch for changes of the files**
in this repository. Once some file **changes it will trigger a rebuild**.

Local preview is served at **`http://127.0.0.1:8000`**.

If you are using [LiveReload](http://livereload.com/extensions/) browser
extension the browser is going to be reloaded automatically once the rebuild is
done. If you are not using LiveReload, you will have to refresh the browser
yourself.

Happy hacking!


## License

The content of the website is licensed under the [Creative Commons Attribution
Share Alike 4.0 International](LICENSE.txt) license.

