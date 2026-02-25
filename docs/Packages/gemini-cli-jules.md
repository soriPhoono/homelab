# Gemini-CLI with Jules Integration

This package integrates `jules` (the AI agent CLI) directly into `gemini-cli`'s environment.

## Overview

`gemini-cli-jules` is a wrapped version of `gemini-cli` that includes `jules-cli` in its `PATH`. This allows `gemini-cli` to invoke `jules` without requiring `jules` to be installed globally in the user's shell environment.

## Implementation Details

- **Overlay**: [gemini-cli-with-jules.nix](../../overlays/gemini-cli-with-jules.nix)
- **Mechanism**: Uses `symlinkJoin` and `makeWrapper` to prefix the `PATH` of the `gemini` binary.
- **Isolation**: Ensures `jules` is not discoverable via the global shell `PATH` but remains accessible to the AI client.

## Usage

Enable it in your home-manager configuration:

```nix
programs.gemini-cli = {
  enable = true;
  enableJules = true; # Uses gemini-cli-jules package
};
```
