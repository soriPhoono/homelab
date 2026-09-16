{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.development.agents.pi-coding-agent;

  inherit
    (lib)
    concatStringsSep
    genAttrs
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    unique
    ;

  allSecrets = unique cfg.secrets;

  hasRuntimeEnvironment = cfg.environment != {} || allSecrets != [];

  runtimeEnvironment = concatStringsSep "\n" (
    (mapAttrsToList (name: value: "${name}=${value}") cfg.environment)
    ++ (map (secret: "${baseNameOf secret}=${config.sops.placeholder.${secret}}") cfg.secrets)
  );

  runtimeEnvironmentFile = config.sops.templates."pi-coding-agent/environment".path;

  piPackage =
    if hasRuntimeEnvironment
    then
      pkgs.symlinkJoin {
        name = "${cfg.package.name or "pi-coding-agent"}-managed";
        paths = [cfg.package];
        meta =
          (cfg.package.meta or {})
          // {
            mainProgram = cfg.package.meta.mainProgram or "pi";
          };
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram "$out/bin/${cfg.package.meta.mainProgram or "pi"}" \
            --run 'set -a; . ${runtimeEnvironmentFile}; set +a'
        '';
      }
    else cfg.package;

  renderDocument = name: document: ''
    # ${name}

    ${
      if builtins.isPath document
      then builtins.readFile document
      else document
    }
  '';

  contextFile = builtins.toPath (toString (pkgs.writeText "pi-context.md" (
    concatStringsSep "\n" (
      map (name: renderDocument name cfg.documents.${name})
      (builtins.sort builtins.lessThan (builtins.attrNames cfg.documents))
    )
  )));

  effectiveContext =
    if cfg.documents != {}
    then contextFile
    else "";
in
  with lib; {
    options.apps.development.agents.pi-coding-agent = mkOption {
      type = types.submodule (_: {
        options = lib.homelab.development.mkAgent {
          name = "pi-coding-agent";
          package = pkgs.pi-coding-agent;
          extraOptions = {};
        };
      });
      description = "Declarative Pi coding agent configuration. Minimal wrapper exposing userSettings + custom packages for hackability.";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets = genAttrs allSecrets (_: {});

        sops.templates."pi-coding-agent/environment" = mkIf hasRuntimeEnvironment {
          content = runtimeEnvironment;
        };

        programs.pi-coding-agent = {
          enable = true;
          package = piPackage;

          inherit (cfg) extraPackages;

          settings = cfg.userSettings;
          context = effectiveContext;
        };
      }
    ]);
  }
