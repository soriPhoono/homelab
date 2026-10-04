# NixOS getting started for Noctalia v5+

Source: <https://docs.noctalia.dev/noctalia/getting-started/nixos/>

<!-- Verbatim upstream page: long code lines and site anchors are kept as-is. -->
<!-- markdownlint-disable MD001 MD013 MD025 MD051 -->

Retrieved: 2026-10-02

Caution

To make Noctalia’s wifi, bluetooth, power-profile, and battery feature
available, please ensure the following NixOS options are enabled:

- `networking.networkmanager.enable`
- `hardware.bluetooth.enable`
- `services.power-profiles-daemon.enable` or `services.tuned.enable`
- `services.upower.enable`

## Installation

A Noctalia package is available on [nixpkgs
unstable](https://search.nixos.org/packages?channel=unstable&show=noctalia).

If you’d prefer the latest git version or would like to use one of the modules,
you can [add the input](#add-input) using your preferred input-pinning method
and optionally use the [binary cache](#binary-cache) to avoid compiling locally.

### Adding the input

- [flakes](#tab-panel-17)
- [tack](#tab-panel-18)
- [npins](#tab-panel-19)
- [tarball](#tab-panel-20)

Add Noctalia to your flake inputs:

```text
{
  inputs = {
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs"; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
    };
  };
}
```

Note

For flakes/tack instructions, we assume you are passing in `inputs` through
`specialArgs` or equivalent.

Add Noctalia to your tack inputs:

```text
tack add noctalia github:noctalia-dev/noctalia
```

If you want to use the cache, make sure to disable any sort of following for
Noctalia’s nixpkgs input.

Note

For flakes/tack instructions, we assume you are passing in `inputs` through
`specialArgs` or equivalent.

Add Noctalia to your npins sources:

```text
npins add github noctalia-dev noctalia --branch main
```

```text
{ pkgs, ... }:
let
  noctalia = import (import ./npins).noctalia {
    inherit pkgs; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
  };
in
  # see installation below
```

Add Noctalia directly using `builtins.fetchTarball`. With pinning:

```text
{ pkgs, ... }:
let
  noctalia-src = let
    commit = ""; # replace this with an actual commit id or tag
  in
    fetchTarball {
      url = "https://github.com/noctalia-dev/noctalia/archive/${commit}.tar.gz";
      sha256 = ""; # replace this with hash from nix build output, or by using `nix-prefetch-url --unpack`
    };


  noctalia = import noctalia-src {
    inherit pkgs; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
  };
in
  # see installation below
```

Without pinning (not recommended):

```text
{ pkgs, ... }:
let
  noctalia-src = fetchTarball "https://github.com/noctalia-dev/noctalia/archive/main.tar.gz";


  noctalia = import noctalia-src {
    inherit pkgs; # this line is optional, prevents downloading two versions of nixpkgs but disables cache
  };
in
  # see installation below
```

### Installing the Package

Note that both the Home Manager and Hjem modules install the package for you, so
you can omit this step.

- [flakes/tack](#tab-panel-21)
- [npins/tarball](#tab-panel-22)

Add the package to your system packages or equivalent:

```text
{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

```text
let
  # see adding the input above
in {
  environment.systemPackages = [
    noctalia.package
  ];
}
```

### Home Manager Module

The Home Manager module allows you to configure Noctalia’s settings [(that you
would otherwise put in `~/.config/noctalia/`)](/noctalia/configuration/) using
nix instead of toml, or allows you to link an existing toml file. It is
optional.

- [flakes/tack](#tab-panel-23)
- [npins/tarball](#tab-panel-24)

```text
{ inputs, ... }:
{
  home-manager.users.drfoobar = {
    imports = [
      inputs.noctalia.homeModules.default
    ];


    programs.noctalia = {
      enable = true;


      settings = { # This may also be a string or path to a .toml file.
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };


        wallpaper = {
          enabled = true;
          default.path = "/path/to/wallpapers/wallpaper.png";
        };
      };
    };
  };
}
```

```text
let
  # see adding the input above
in {
  home-manager.users.drfoobar = {
    imports = [
      noctalia.homeModule
    ];


    programs.noctalia = {
      enable = true;


      settings = { # This may also be a string or path to a .toml file.
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };


        wallpaper = {
          enabled = true;
          default.path = "/path/to/wallpapers/wallpaper.png";
        };
      };
    };
  };
}
```

### Hjem Module

For those using Hjem instead of Home Manager, a Hjem module is also available.

- [flakes/tack](#tab-panel-25)
- [npins/tarball](#tab-panel-26)

```text
{ inputs, ... }:
{
  hjem = {
    extraModules = [
      inputs.noctalia.hjemModules.default
    ];


    users.drfoobar = {
      programs.noctalia = {
        enable = true;


        settings = { ... };
      };
    };
  };
}
```

```text
let
  # see adding the input above
in {
  hjem = {
    extraModules = [
      noctalia.hjemModule
    ];


    users.drfoobar = {
      programs.noctalia = {
        enable = true;


        settings = { ... };
      };
    };
  };
}
```

### NixOS Module

The NixOS module installs the package system-wide and can enable some
recommended services.

- [flakes/tack](#tab-panel-27)
- [npins/tarball](#tab-panel-28)

```text
{ inputs, ... }:
{
  imports = [
    inputs.noctalia.nixosModules.default
  ];


  programs.noctalia = {
    enable = true;


    # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
    recommendedServices.enable = true;
  };
}
```

```text
let
  # see adding the input above
in {
  imports = [
    noctalia.nixosModule
  ];


  programs.noctalia = {
    enable = true;


    # Enables NetworkManager, Bluetooth, UPower, and a power profile service.
    recommendedServices.enable = true;
  };
}
```

### Systemd Service

Each of the above modules includes a systemd user service for Noctalia, which
can be enabled by setting `programs.noctalia.systemd.enable = true`.

Note

When using the service, it is recommended to enable
`launch_apps_as_systemd_services`, otherwise any apps launched by Noctalia will
be terminated when the service restarts.

### Binary Cache

Pre-built binaries are available on
[Cachix](https://app.cachix.org/cache/noctalia), so you can skip compiling
locally.

You can configure the substituter either in your NixOS config, flake, or
`/etc/nix/nix.conf`:

Caution

To use the binary cache, you have to omit `inputs.nixpkgs.follows` from the
Noctalia input with flakes/tack or avoid `inherit pkgs;` with npins/tarball.

You can add the cache either to your flake, nixos configuration, or
`/etc/nix/nix.conf`.

- [configuration.nix](#tab-panel-29)
- [flake.nix](#tab-panel-30)
- [nix.conf](#tab-panel-31)

```text
nix.settings = {
  extra-substituters = [ "https://noctalia.cachix.org" ];
  extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
};
```

```text
nixConfig = {
  extra-substituters = [ "https://noctalia.cachix.org" ];
  extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
};
```

```text
extra-substituters = https://noctalia.cachix.org
extra-trusted-public-keys = noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=
```

Overriding any of Noctalia’s inputs (e.g. via `inputs.nixpkgs.follows` with
flakes) changes the derivation hash, causing cache misses.

Additionally, tracking `main` directly may pull in a commit that hasn’t been
cached yet by CI.

To avoid this, the
[`cachix`](https://github.com/noctalia-dev/noctalia/tree/cachix) branch always
points to the latest cached commit. Pinning to this branch guarantees you always
track the latest commit that has already been cached:

- [flakes](#tab-panel-32)
- [tack](#tab-panel-33)
- [npins](#tab-panel-34)
- [tarball](#tab-panel-35)

```text
noctalia.url = "github:noctalia-dev/noctalia/cachix";
```

```text
tack add noctalia github:noctalia-dev/noctalia/cachix
```

```text
npins add github noctalia-dev noctalia --branch cachix
```

Make sure not to update your tarball to a commit earlier than the latest commit
on the cachix branch.
