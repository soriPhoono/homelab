{pkgs, ...}: {
  core = {
    user = {
      name = "sphoono";
      shell = pkgs.fish;
    };
    android.enable = true;
    timeZone = "America/Chicago";
  };
}
