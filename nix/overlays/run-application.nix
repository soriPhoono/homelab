_: _final: prev: {
  run-application = prev.writeShellApplication {
    name = "run-application";
    runtimeInputs = with prev; [
      runapp
    ];
    text = ''
      runapp -- "$@"
    '';
  };
}
