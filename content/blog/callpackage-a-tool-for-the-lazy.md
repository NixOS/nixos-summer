---
title: callPackage, a tool for the lazy
date: 2022-08-25
extra:
  author: Norbert Melzer
---

In [`nixpkgs`](https://github.com/nixos/nixpkgs), there is a massive use of the
`callPackage` funcion, which usage provides us with a lot of benefits.

## Basic examples

Though before even discussing the benefits, lets see how it actually gets used.

Given are these 2 files `hello.nix` and `default.nix`:

```nix
# Usually I would prefer the usage of nix flakes, though that would
# introduce a lot of boilerplate in the examples for no reason,
# therefore I will use diamond pathes and `import` for simplicity.
```

```nix
# default.nix
let pkgs = import <nixpkgs> {}; in
pkgs.callPackage ./hello.nix {}
```

```nix
# hello.nix
{writeShellScriptBin}:
writeShellScriptBin "hello" ''
  echo "hello, world!"
''
```

Building using `nix-build` will produce `./result/bin/hello`, and running it will
nicely greet you.

As you can see, `writeShellScriptBin` gets passed in by `callPackage` automatically.

For this simple setup, having to create an extra file, seems to be a lot of
boilerplate, though if you continue reading, you will see, it is worth it!

## 1. Benefit: parametrized builds

Now lets change the `default.nix`:

```nix
# default.nix
let pkgs = import <nixpkgs> { }; in
{
  hello = pkgs.callPackage ./hello.nix { };
}
```

Now we build using `nix-build -A hello`, the outcome will be the same as above.

Now to "parametrize" the build we also change the `hello.nix` a bit:

```nix
# hello.nix
{ writeShellScriptBin
, audience ? "world"
}:
writeShellScriptBin "hello" ''
  echo "hello, ${audience}!"
''
```

Building this will still yield the same output as before, though now things get
interesting, alter your `default.nix` yet another time:

```nix
# default.nix
let pkgs = import <nixpkgs> { }; in
{
  hello = pkgs.callPackage ./hello.nix { };
  people = pkgs.callPackage ./hello.nix { audience = "people"; };
}
```

Building via `nix-build -A people` will now yield a script that prints "hello,
people" instead.

We can use the very same syntax to also overwrite the automatically discovered
arguments like `writeShellScriptBin`, though that doesn't make sense here.

For a go program though that expects `buildGoModule` it is common to see some
expression like `callPackage ./go-program.nix { buildGoModule = buildGo116Module; }`
to enforce a certain go compiler version.

## 2. Benefit: overrides

As a consequence from the parametrized builds, we can also change the value of
the parameters after the fact, using the derivations `override` funcion.

Consider this new `default.nix`:

```nix
# default.nix
let pkgs = import <nixpkgs> { }; in
rec {
  hello = pkgs.callPackage ./hello.nix { };
  people = pkgs.callPackage ./hello.nix { audience = "people"; };
  folks = hello.override { audience = "folks"; };
}
```

Building and running the `folks` attribute, will give again a new version of the
script.

All the other parameters will remain the same as the have been when `hello` was
instantiated.

This is especially useful and often seen on packages that provide a whole lot of
options to optimize the build.

An example to mention here is the `neovim` attribute in nixpkgs, which has has 
some overrideable arguments like `extraLuaPackages`, `extraPythonPackages`, or
`withRuby`.

## 3. Benefit: modifiable

And now I want to introduce one of my most favorite benefits:

You can actually create your own version of `callPackage`, which comes in quite
handy when you have large sets where the attributes to be built depend on each
other.

<NoteBox>
    In the next examples I will not implement or show the "called" files, as I
    think they are not necessary to understand the point I want to make.
</NoteBox>

Consider the following initial version:

```nix
# default.nix
let pkgs = import <nixpkgs> { }; in
rec {
  a = pkgs.callPackage ./a.nix { };
  b = pkgs.callPackage ./b.nix { inherit a; };
  c = pkgs.callPackage ./c.nix { inherit b; };
  d = pkgs.callPackage ./d.nix { };
  e = pkgs.callPackage ./e.nix { inherit c d; };
}
```

Here you have to remember passing required arguments that are not in nixpkgs'
toplevel manually.

This can become quite tedious quickly, especially the larger the set becomes.

Therefore we can use `lib.callPackageWith` to create our own `callPackage` version.

```nix
# default.nix
let
  pkgs = import <nixpkgs> { };
  callPackage = lib.callPackageWith (pkgs // packages);
  packages = {
    a = callPackage ./a.nix { };
    b = callPackage ./b.nix { };
    c = callPackage ./c.nix { };
    d = callPackage ./d.nix { };
    e = callPackage ./e.nix { };
  };
in
  packages
```

Our modified `callPackage` now will exactly "know" how to resolve the dependencies
through the set defined by `pkgs // packages`.

Nix' lazyness does us a good favour here and makes this actually possible.

## Summary

So using `callPackage` doesn't only make your code uniform to what you see a lot
in nixpkgs already, it also gives you some things for free:

1. parametrized builds
2. overrideable builds
3. cleaner implementation of large interdepending package sets

## Further reading

There is also `callPackages` and `lib.callPackages` which do a pretty similar
thing, though they expect that the returnvalue is *not* a package, but a
packageset.
Each of the attributes in the returned set will then be overrideable as if you
had called `callPackage` on that.

```nix
# callpackages.nix
{ runCommand }:
{
  a = runCommand "a" { } "echo a > $out";
  b = runCommand "b" { } "echo b > $out";
}
```

```
$ nix-build -E 'with import <nixpkgs> {}; (callPackages ./callpackages.nix { }).a.override { }'
this derivation will be built:
  /nix/store/4sjzxijjfamjqgr8237lr638b8qkabnk-a.drv
building '/nix/store/4sjzxijjfamjqgr8237lr638b8qkabnk-a.drv'...
/nix/store/4n3w8mkswwpfa1vvx3012xbaqskflg2z-a
$ nix-build -E 'with import <nixpkgs> {}; (callPackages ./callpackages.nix { }).a.override { runCommand = runCommandCC; }'
this derivation will be built:
  /nix/store/qj9hg9qiahggi4yk6qsh4wv33jl33f36-a.drv
building '/nix/store/qj9hg9qiahggi4yk6qsh4wv33jl33f36-a.drv'...
/nix/store/50llkafby4vci46qda0xlva24mlghwr0-a
```

As you can see, 2 different pathes have been produced, due to the fact that we
replaced the `runCommand`.