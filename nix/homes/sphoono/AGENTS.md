# SPhoono user configuration

This folder manages the sphoono core home manager configurations
The default admin user and author of this repo

## Structure

This folder has the following structure:

- `configs/`: This directory contains all per application/topic configuration
- `default.nix`: The core user configuration file, imports all other configurations
- `secrets.yml`: The secrets vault for this user, holds all keys, tokens, and secrets
- `theme.nix`: The user configuration file for theming using stylix
