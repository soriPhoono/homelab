{ lib, ... }: {
  den = {
    schema.user = { };
    aspects.desktop.components.credentials = {
      nixos = {

      };
      homeManager =
        { pkgs, config, ... }:
        let
          modulePath = "desktop.components.credentials.gpg";
          cfg = config.${modulePath};
        in
        {

          programs.gpg = {
            enable = true;
            mutableKeys = true;
            mutableTrust = true;
          };
          services.gpg-agent = {
            enable = true;
            enableSshSupport = true;
            enableExtraSocket = true;
            pinentry.package = pkgs.writeShellApplication {
              name = "pinentry-script";
              runtimeInputs = [
                pkgs.pinentry-curses
                cfg.pinentry-package
                pkgs.procps
                pkgs.gnugrep
              ];
              text = ''
                is_ssh=false

                if [ -n "''${SSH_CLIENT:-}" ] || [ -n "''${SSH_TTY:-}" ] || [ -n "''${SSH_CONNECTION:-}" ]; then
                  is_ssh=true
                fi

                if [ "$is_ssh" = false ]; then
                  target_tty="''${GPG_TTY:-}"
                  if [ -z "$target_tty" ] || [ "$target_tty" = "not a tty" ]; then
                    target_tty=$(tty 2>/dev/null || true)
                  fi

                  if [ -n "$target_tty" ] && [ -e "$target_tty" ]; then
                    tty_short=$(basename "$target_tty")
                    for pid in $(ps -o pid= -t "$tty_short" 2>/dev/null || true); do
                      if [ -r "/proc/$pid/environ" ]; then
                        if grep -q -z "^SSH_CLIENT=\|^SSH_TTY=\|^SSH_CONNECTION=" "/proc/$pid/environ" 2>/dev/null; then
                          is_ssh=true
                          break
                        fi
                      fi
                      curr="$pid"
                      while [ -n "$curr" ] && [ "$curr" -gt 1 ] 2>/dev/null; do
                        comm=$(cat "/proc/$curr/comm" 2>/dev/null || true)
                        if [ "$comm" = "sshd" ]; then
                          is_ssh=true
                          break 2
                        fi
                        curr=$(ps -o ppid= -p "$curr" 2>/dev/null | tr -d ' ' || true)
                      done
                    done
                  fi
                fi

                if [ "$is_ssh" = false ]; then
                  for pid in $(pgrep -u "$(id -u)" 2>/dev/null || true); do
                    if [ -r "/proc/$pid/environ" ]; then
                      if grep -q -z "^SSH_CLIENT=\|^SSH_TTY=\|^SSH_CONNECTION=" "/proc/$pid/environ" 2>/dev/null; then
                        is_ssh=true
                        break
                      fi
                    fi
                  done
                fi

                if [ "$is_ssh" = true ]; then
                  export GPG_TTY="''${GPG_TTY:-$(tty 2>/dev/null || echo /dev/tty)}"
                  export TERM="''${TERM:-xterm-256color}"
                  exec ${lib.getExe pkgs.pinentry-curses} "$@"
                elif [ -n "''${WAYLAND_DISPLAY:-}" ] || [ -n "''${DISPLAY:-}" ]; then
                  exec ${lib.getExe cfg.pinentryPackage} "$@"
                else
                  export GPG_TTY="''${GPG_TTY:-$(tty 2>/dev/null || echo /dev/tty)}"
                  export TERM="''${TERM:-xterm-256color}"
                  exec ${lib.getExe pkgs.pinentry-curses} "$@"
                fi
              '';
            };
          };
        };
    };
  };
}
