_: {
  # GitHub CLI. Login is imperative: run `gh auth login` once per host.
  den.aspects.spookyskelly.development.tools.gh.homeManager = _: {
    programs.gh = {
      enable = true;
      settings.git_protocol = "ssh";
    };
  };
}
