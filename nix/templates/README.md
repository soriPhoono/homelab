# Templates

This directory contains flake templates for quickly scaffolding new projects or components.

## Usage

List available templates:

```bash
nix flake show templates
```

Initialize a template:

```bash
nix flake init -t .#<template-name>
```

## Creating a Template

1. Create a directory in `templates/`.
1. Add a `flake.nix` inside it describing the template.
1. Add the boilerplate files you want to be copied.
