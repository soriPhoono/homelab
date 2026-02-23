{
  pkgs,
  lib,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages =
      [
        nil
        alejandra
        vulnix

        age
        agenix
        sops
        ssh-to-age

        terraform
        jq
      ]
      ++ lib.optional stdenv.isLinux [
        disko
        nixos-facter
      ];

    shellHook = ''
      ${config.pre-commit.shellHook}
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      export TF_VAR_proxmox_api_token="$PROXMOX_API_TOKEN"

      # Deploy gemini mcp servers to antigravity if `antigravity` is the current editor
      # Both VS Code and antigravity set TERM_PROGRAM=vscode, but antigravity's GIT_ASKPASS path
      # contains 'antigravity' (e.g. /nix/store/...-antigravity-.../antigravity)
      if [[ "$VSCODE_GIT_ASKPASS_NODE" == *"antigravity"* ]]; then
        # Read the mcpServers json field from .gemini/settings.json and copy it to antigravity's config directory
        # ~/.gemini/antigravity/mcp_config.json
        mkdir -p ~/.gemini/antigravity
        ${pkgs.jq}/bin/jq '{mcpServers: .mcpServers}' ${./.gemini/settings.json} > ~/.gemini/antigravity/mcp_config.json
      fi

      # Deploy GitHub Actions from actions.nix when that file is modified to create reactive checks in GitHub CI
      mkdir -p ./.github/workflows
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: let
          safeName = lib.removeSuffix ".yml" name;
        in ''
          cp -f ${file} ./.github/workflows/${safeName}.yml
          chmod +w ./.github/workflows/${safeName}.yml
        '')
        config.githubActions.workflowFiles)}
    '';
  }
