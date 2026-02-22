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
      ]
      ++ lib.optional stdenv.isLinux [
        disko
        nixos-facter
      ];

    shellHook = ''
      ${config.pre-commit.shellHook}
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      # Deploy gemini mcp servers to antigravity if `antigravity` is the current editor
      # Both VS Code and antigravity set TERM_PROGRAM=vscode, but antigravity's GIT_ASKPASS path
      # contains 'antigravity' (e.g. /nix/store/...-antigravity-.../antigravity)
      if [[ "$VSCODE_GIT_ASKPASS_NODE" == *"antigravity"* ]]; then
        # Read the mcpServers json field from .gemini/settings.json and copy it to antigravity's config directory
        # ~/.gemini/antigravity/mcp_config.json
        mkdir -p ~/.gemini/antigravity
        ${pkgs.jq}/bin/jq '{mcpServers: .mcpServers}' ${./.gemini/settings.json} > ~/.gemini/antigravity/mcp_config.json
      fi
    '';
  }
