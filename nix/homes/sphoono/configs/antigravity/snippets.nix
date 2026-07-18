_: {
  apps.development.editors.antigravity = {
    # Common snippets applied to every active profile.
    #
    # globalSnippets are keyed by snippet name and available in all languages.
    # languageSnippets are keyed by language identifier (e.g. "nix", "json").
    # Both can be extended per-profile via extensionProfiles.<name>.globalSnippets
    # and extensionProfiles.<name>.languageSnippets respectively.
    common = {
      # Global (cross-language) snippets
      globalSnippets = {
        "Log to console" = {
          scope = "javascript,typescript,javascriptreact,typescriptreact";
          prefix = ["clog" "log"];
          body = [''console.log('$1', $2);$0''];
          description = "Log to the console";
        };

        "TODO comment" = {
          prefix = ["todo"];
          body = [''// TODO: $1$0''];
          description = "Insert a TODO comment";
        };

        "FIXME comment" = {
          prefix = ["fixme"];
          body = [''// FIXME: $1$0''];
          description = "Insert a FIXME comment";
        };

        "HACK comment" = {
          prefix = ["hack"];
          body = [''// HACK: $1$0''];
          description = "Insert a HACK comment";
        };

        "Shebang script" = {
          prefix = ["shebang" "shbang"];
          body = [''#!/usr/bin/env ''${1|bash,python,node,sh|}''];
          description = "Insert a shebang line";
        };
      };

      # Language-specific snippets
      languageSnippets = {
        # --- Nix snippets ---
        nix = {
          "Nix module boilerplate" = {
            prefix = ["module" "nixmod"];
            body = [
              ''{ lib, config, pkgs, ... }:''
              ''''
              ''with lib; { ''
              ''options.''${1:namespace}.''${2:name} = { ''
              ''enable = mkEnableOption "''${3:description}";''
              ''};''
              ''''
              ''config = mkIf cfg.enable {''
              ''$0''
              ''};''
              ''}''
            ];
            description = "Standard NixOS/home-manager module skeleton";
          };

          "mkIf wrapper" = {
            prefix = ["mkif"];
            body = [''mkIf $1 {'' ''$0'' ''}''];
            description = "Wrap config in mkIf";
          };

          "mkMerge" = {
            prefix = ["mkmerge"];
            body = [''mkMerge ['' ''$0'' '']''];
            description = "mkMerge block";
          };

          "mkOption (string)" = {
            prefix = ["mkoptstr"];
            body = [
              ''$1 = mkOption {''
              "  type = types.str;"
              "  default = $2;"
              ''description = "''${3:description}";''
              ''};''
            ];
            description = "Create a string mkOption";
          };

          "mkEnableOption" = {
            prefix = ["mkenable"];
            body = [''enable = mkEnableOption "$1";''];
            description = "Create a boolean enable option";
          };

          "let in block" = {
            prefix = ["letin"];
            body = [
              ''let''
              ''$1 = $2;''
              ''in''
              ''$0''
            ];
            description = "let-in expression block";
          };

          "Attr set" = {
            prefix = ["attrs"];
            body = [
              ''{''
              ''$1 = $2;''
              ''$0''
              ''}''
            ];
            description = "Attribute set literal";
          };

          "List literal" = {
            prefix = ["list"];
            body = [
              ''[''
              ''$1''
              ''$0''
              '']''
            ];
            description = "List literal";
          };

          "Filter attrs" = {
            prefix = ["filterattrs"];
            body = [''lib.filterAttrs (name: value: $1) $2''];
            description = "filterAttrs";
          };

          "Optional string" = {
            prefix = ["optstr"];
            body = ["lib.optionalString $1 ''" "  $0" "''"];
            description = "lib.optionalString wrapper";
          };

          "Sops secret entry" = {
            prefix = ["sopssecret"];
            body = [''"$1" = {};''];
            description = "Sops-nix secret entry";
          };
        };

        # --- JSON snippets ---
        json = {
          "JSON key-value" = {
            prefix = ["kv"];
            body = [''"$1": "$2",''];
            description = "JSON key-value pair";
          };
        };

        # --- Markdown snippets ---
        markdown = {
          "Link" = {
            prefix = ["link"];
            body = [''[$1]($2)''];
            description = "Markdown link";
          };

          "Code block" = {
            prefix = ["codeblock" "cb"];
            body = [
              ''```$1''
              ''$0''
              ''```''
            ];
            description = "Fenced code block";
          };

          "Table" = {
            prefix = ["table"];
            body = [
              ''| $1 | $2 |''
              ''|------------|------------|''
              ''| $3 | $4 |''
              ''$0''
            ];
            description = "Markdown table";
          };

          "Task list" = {
            prefix = ["tasklist" "tlist"];
            body = [''- [ ] $1'' ''$0''];
            description = "Task list item";
          };
        };

        # --- Shell script snippets ---
        shellscript = {
          "Shell script boilerplate" = {
            prefix = ["shtemplate" "shscript"];
            body = [
              "#!/usr/bin/env bash"
              "set -euo pipefail"
              "IFS=$'\\n\\t'"
              ""
              "$1"
            ];
            description = "Bash script boilerplate with strict mode";
          };

          "for loop" = {
            prefix = ["for"];
            body = [
              "for $1 in $2; do"
              "  $3"
              "done"
            ];
            description = "For loop in bash";
          };

          "if statement" = {
            prefix = ["if"];
            body = [
              "if [[ $1 ]]; then"
              "  $2"
              "fi"
            ];
            description = "If statement in bash";
          };
        };

        # --- YAML snippets ---
        yaml = {
          "Key-value string" = {
            prefix = ["kv"];
            body = ["$1: \"$2\""];
            description = "YAML key-value pair (string)";
          };
        };

        # --- Go snippets ---
        go = {
          "errcheck" = {
            prefix = ["err"];
            body = [
              ''if err != nil {''
              ''return ''${1:err}''
              ''}''
            ];
            description = "Error check and return";
          };
          "test" = {
            prefix = ["test"];
            body = [
              ''func Test''${1:Name}(t *testing.T) {''
              ''$0''
              ''}''
            ];
            description = "Go unit test function";
          };
          "printf" = {
            prefix = ["printf" "fp"];
            body = [
              ''fmt.Printf("''${1:var}: %+v\n", ''${1:var})''
            ];
            description = "Printf print helper";
          };
        };

        # --- Rust snippets ---
        rust = {
          "test" = {
            prefix = ["test" "tmod"];
            body = [
              ''#[cfg(test)]''
              ''mod tests {''
              ''use super::*;''
              ''''
              ''#[test]''
              ''fn test_''${1:name}() {''
              ''$0''
              ''}''
              ''}''
            ];
            description = "Rust test module and test case";
          };
          "derive" = {
            prefix = ["derive" "drv"];
            body = [
              ''#[derive(Debug, Clone, PartialEq, Eq''${1:, Serialize, Deserialize})]''
            ];
            description = "Common derive traits";
          };
          "maperr" = {
            prefix = ["maperr" "me"];
            body = [
              ''map_err(|e| ''${1:anyhow!("''${2:failed}: {:?}", e)})''
            ];
            description = "map_err with anyhow/eyre";
          };
        };

        # --- Python snippets ---
        python = {
          "main" = {
            prefix = ["main"];
            body = [
              ''if __name__ == "__main__":''
              ''''${1:main()}''
            ];
            description = "Python standard main guard";
          };
          "try" = {
            prefix = ["try"];
            body = [
              ''try:''
              ''$1''
              ''except ''${2:Exception} as e:''
              ''''${3:raise e}''
            ];
            description = "Try-except block";
          };
        };

        # --- HCL / Terraform snippets ---
        terraform = {
          "resource" = {
            prefix = ["resource" "res"];
            body = [
              ''resource "''${1:type}" "''${2:name}" {''
              ''$0''
              ''}''
            ];
            description = "Terraform resource definition";
          };
          "variable" = {
            prefix = ["variable" "var"];
            body = [
              ''variable "''${1:name}" {''
              ''type        = ''${2:string}''
              ''description = "''${3:description}"''
              ''default     = ''${4:null}''
              ''}''
            ];
            description = "Terraform input variable definition";
          };
        };
      };
    };
  };
}
