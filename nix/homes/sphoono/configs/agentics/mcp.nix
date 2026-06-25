{
  userapps.development.agents.agentics = {
    mcpServers = {
      http = {
        github = {
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = {
              secret = "api/GITHUB_API_KEY";
              prefix = "Bearer ";
            };
          };
        };

        exa = {
          url = "https://mcp.exa.ai";
          headers = {
            x-api-key = {
              secret = "api/EXA_API_KEY";
            };
          };
        };

        context7 = {
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = {
              secret = "api/CONTEXT7_API_KEY";
            };
          };
        };
      };
    };
  };
}
