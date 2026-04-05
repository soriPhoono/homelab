_: _self: _super: {
  # Constructs the appropriate launch command for an application or terminal,
  # respecting the UWSM environment if enabled.
  launchApp = nixosConfig: terminal: app: let
    isUwsmEnabled = nixosConfig != null && (nixosConfig.desktop.environments.uwsm.enable or false);
    hasApp = app != null && app != "";
  in
    if isUwsmEnabled
    then
      if terminal
      then
        if hasApp
        then "uwsm app -s a -T -- ${app}"
        else "uwsm app -s a -T"
      else if hasApp
      then "uwsm app -s a -- ${app}"
      else throw "Cannot launch an empty application"
    else if terminal
    then
      if hasApp
      then "$TERMINAL -e ${app}"
      else "$TERMINAL"
    else if hasApp
    then "${app}"
    else throw "Cannot launch an empty application";
}
