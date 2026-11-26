# obs-studio-mcp: an MCP server for OBS Studio over obs-websocket v5. Reads
# OBS_MCP_HOST, OBS_MCP_PORT and OBS_MCP_PASSWORD from the environment.
#
# Pinned to mcp 1.x: upstream requires mcp<2 and nixpkgs' default mcp is 2.x.
{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "obs-studio-mcp";
  version = "0.5.1";
  pyproject = true;

  src = fetchPypi {
    pname = "obs_studio_mcp";
    inherit version;
    hash = "sha256-IUxynsbIlvp/bMePDTlAr2AQ9rg8RaQHRC+R34tfFJo=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    mcp_1
    obsws-python
  ];

  pythonImportsCheck = [ "obs_studio_mcp" ];

  meta = {
    description = "MCP server for controlling OBS Studio over obs-websocket";
    homepage = "https://github.com/aaronckj/obs-studio-mcp";
    license = lib.licenses.mit;
    mainProgram = "obs-studio-mcp";
  };
}
