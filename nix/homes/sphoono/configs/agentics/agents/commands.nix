_: {
  userapps.development.agentics.agents.commands.registry = {
    commit = ''
      # Commit Command

      Create a git commit with a descriptive message.
      Usage: /commit [message]
    '';
    fix = ''
      # Fix Command

      Analyze the current issue and suggest a fix.
      Usage: /fix [description]
    '';
    review = ''
      # Review Command

      Review the current changes and provide feedback.
      Usage: /review
    '';
    changelog = ''
      # Changelog Command

      Update CHANGELOG.md with a new entry.
      Usage: /changelog [version] [change-type] [message]
    '';
  };
}
