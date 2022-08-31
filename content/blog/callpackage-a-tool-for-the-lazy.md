---
title: callPackage, a tool for the lazy
date: 2022-08-25
extra:
  author: Norbert Melzer
---

The Nix package manager ships with a a special-purpose programming language for creating packages and configurations: the Nix language.
It is used to build the Nix package collection, known as [`nixpkgs`](https://github.com/nixos/nixpkgs) – the largest, most up-to-date open source software distribution in the world.

Being purely functional, the Nix language allows declaring custom functions to abstract over common patterns.
One such pattern is parametrization of package definitions, that is, builds which can vary by their dependencies or settings.

`nixpkgs` is a sizeable software project on it's own, with coding conventions and idioms that have emerged over the years.
It has [established a convention](https://github.com/NixOS/nixpkgs/pull/9869) of composing parameterized packages with automatic settings through a function named [`callPackage`](https://github.com/NixOS/nixpkgs/commit/fd268b4852d39c18e604c584dd49a611dc795a9b).

This article shows how to use it and why it's beneficial.

## Basic examples

Before even discussing the benefits, let's see how it actually gets used.

Given are the files `hello.nix` and `default.nix`:

```nix
# default.nix
let pkgs = import <nixpkgs> {}; in
pkgs.callPackage ./hello.nix {}
```

`default.nix` produces a *derivation* from the contents of `hello.nix`.
This what the Nix package manager calls its build results (which are often packaged executables, but can be arbitrary files), and what the Nix language calls the data type of such an expression.

```nix
# hello.nix
{ writeShellScriptBin }:
writeShellScriptBin "hello" ''
  echo "hello, world!"
''
```

`hello.nix` declares a function which takes as argument an attribute set with one element `writeShellScriptBin`. `writeShellScriptBin` is also a function, which happens to return a derivation. The build result in this case is an executable shell script with the contents `echo "hello world"` named `"hello"`.

Building using `nix-build` (which implicitly evaluates `default.nix` unless told otherwise) will produce `./result/bin/hello`, and running the resulting script will nicely greet you.

As you can see, the argument `writeShellScriptBin` gets filled in automatically when the function in `hello.nix` is evaluated.
Explaining in detail how this happens is not in the scope of this blogpost.
This automatic filling of attributes is what `callPackage` is responsible for.
It passes attributes that exist in the `pkgs` attribute set to the called function, simply matching by name.

It may appear cumbersome to create an extra file for the package in such a simple setup.
But in fact, this is exactly how `nixpkgs` is organized: every package is a file that declares a function.
This function takes as arguments the package's dependencies.

If you continue reading, you will see the benefits of this pattern!

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

Building this will still yield the same output as before.

Things get more interesting when we alter `default.nix` another time, by adding a new attribute `people` to the result.

Note how we pass a parameter `audience` in the second argument to `callPackage`, which is passed on to the function defined in `hello.nix`:

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

`callPackage` adds more convenience by adding an attribute to the derivation it returns: the `override` function.

That is, as a consequence of handling parametrized builds with `callPackage`, we can also change the value of the parameters after the fact, using the derivation's `override` function.

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

Note that the resulting attribute set is now recursive (by the keyword `rec`), that is, attribute values can refer to names from within the same attribute.

Here we take the `hello` derivation and call its `override` attribute as a function, passing the attribute set `{  `audience = "folks"; }`. `override` passes `audience` to the original function in `hello.nix` - to be precise, *overrides* whatever arguments have been passed in the original `callPackage` that produced the derivation `hello`.

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

Note that `inherit a;` is equivalent to `a = a;`.
That is, we're passing previously declared derivations as arguments to other derivations through `callPackage`.

In this case you have to remember to manually pass arguments required by each package in the respective `.nix` file if they are not in `nixpkgs`.
This is due to how `pkgs.callPackage` works: it passes attributes that exist in `pkgs` to the called function if the argument names match.

If `./b.nix` requires an argument `a` but there is no `pkgs.a`, the function call will produce an error.

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
