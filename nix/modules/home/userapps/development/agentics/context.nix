{
  lib,
  nixosConfig ? null,
  ...
}:
with lib; {
  options.userapps.development.agentics.context = with types; {
    user = mkOption {
      type = nullOr str;
      default = null;
      description = "User-level context to be included in agentic guidance.";
    };

    system = mkOption {
      type = nullOr str;
      default = nixosConfig.core.context.system or null;
      description = "System-level context to be included in agentic guidance.";
    };

    __functor = mkOption {
      type = unspecified;
      internal = true;
      default = self: _: ''
        # Agent Guidance Context

        This context is used to provide additional information to agentic applications, enhancing their ability to make informed decisions and perform tasks effectively. The context is divided into two main categories for this section: System Environment and User Identity & Workspace Preferences. Later details regarding operational expectations will be given in later sections.

        ## System Environment
        ${optionalString (self.system != null) self.system}

        ## User Identity & Workspace Preferences
        ${optionalString (self.user != null) self.user}
      '';
    };
  };
}
