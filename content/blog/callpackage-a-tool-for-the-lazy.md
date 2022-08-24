---
title: callPackage, a tool for the lazy
date: 2022-08-25
extra:
  author: Norbert Melzer
---

In [`nixpkgs`](https://github.com/nixos/nixpkgs), there is a massive use of the
`callPackage` function, which provides us with a lot of benefits.

## Basic examples

Before even discussing the benefits, let's see how it actually gets used.

Given are the files `hello.nix` and `default.nix`:

```nix
# default.nix
let pkgs = import <nixpkgs> {}; in
pkgs.callPackage ./hello.nix {}
```

```nix
# hello.nix
{ writeShellScriptBin }:
writeShellScriptBin "hello" ''
  echo "hello, world!"
''
```

Building using `nix-build` (which implicitly evaluates `default.nix` unless told otherwise) will produce `./result/bin/hello`, and running the resulting script will nicely greet you.

As you can see, `writeShellScriptBin` gets passed in by `callPackage` automatically.

For this simple setup, having to create an extra file, seems to be a lot of
boilerplate, though if you continue reading, you will see, it is worth it!

## 1. Benefit: parametrized builds

Let's change the `default.nix`.

Now it does not produce a single derivation any more, but an attribute set with the attribute `hello` containing the original derivation:

```nix
# default.nix
let pkgs = import <nixpkgs> { }; in
{
  hello = pkgs.callPackage ./hello.nix { };
}
```

When we build it with `nix-build -A hello` (accessing the attribtue `hello` with the `-A` flag), the outcome will be the same as before.

We also change `hello.nix` to add an additional parameter `audience` with default value `"world"`:

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

Building via `nix-build -A people` will now yield a script that prints `hello,
people`.

We could use the very same syntax to also overwrite the automatically discovered
arguments like `writeShellScriptBin`, though that doesn't make sense here.

For example, a Go program that expects `buildGoModule` it is common to see some
expression like `callPackage ./go-program.nix { buildGoModule = buildGo116Module; }`
to enforce a certain Go compiler version.

## 2. Benefit: overrides

As a consequence from the parametrized builds, we can also change the value of
the parameters after the fact, using the derivations `override` function.

Consider this new `default.nix`, where we added a third attribute `folks`:

```nix
# default.nix
let pkgs = import <nixpkgs> { }; in
rec {
  hello = pkgs.callPackage ./hello.nix { };
  people = pkgs.callPackage ./hello.nix { audience = "people"; };
  folks = hello.override { audience = "folks"; };
}
```

Building and running the `folks` attribute with `nix-build -A folks` will again produce a new version of the script.
It will print, as you may expect, `hello folks`.

All the other parameters will remain the same as they have been when `hello` was
instantiated.

This is especially useful and often seen on packages that provide many
options to customize the build.

An example to mention here is the [`neovim`](https://search.nixos.org/packages?channel=22.05&show=neovim&from=0&size=50&sort=relevance&type=packages&query=neovim) attribute in nixpkgs, which has has 
some overrideable arguments like `extraLuaPackages`, `extraPythonPackages`, or
`withRuby`.

## 3. Benefit: modifiable

And now I want to introduce one of my favorite benefits:

You can actually create your own version of `callPackage`. This comes in quite
handy when you have large sets where the attributes to be built depend on each
other.

> **Note**
> In the next examples I will not implement or show the "called" 
> files, as I think they are not necessary to understand the point I
> want to make.

Consider the following attribute set of derivations:

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

Therefore we can use `lib.callPackageWith` to create our own `callPackage`:

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

Nix' laziness does us a good favour here and makes this actually possible.

## Summary

Using `callPackage` does not only follow `nixpkgs` conventions, making your code easy to follow for experienced Nix users. It also gives you some things for free:

1. parametrized builds
2. overrideable builds
3. cleaner implementation of large interdepending package sets
