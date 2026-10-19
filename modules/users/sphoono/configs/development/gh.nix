_: {
  # GitHub CLI. Login is imperative: run `gh auth login` once per host.
  den.aspects.sphoono.development.homeManager = _: {
    programs.gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
  };
}
