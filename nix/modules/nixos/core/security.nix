_: {
  security.sudo = {
    execWheelOnly = true;
    extraConfig = ''
      Defaults timestamp_timeout=15
      Defaults lecture=always
    '';
  };
}
