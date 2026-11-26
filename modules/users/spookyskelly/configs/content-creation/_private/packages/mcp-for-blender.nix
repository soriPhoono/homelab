# MCP for Blender (formerly blender-mcp): an MCP server that drives Blender
# through a socket opened by its bundled addon. The addon ships inside the
# package at blender_mcp/bundled/addon.py; passthru.addonPath locates it.
#
# Pinned to mcp 1.x: upstream requires mcp<2 and nixpkgs' default mcp is 2.x.
{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "mcp-for-blender";
  version = "2.3.3";
  pyproject = true;

  src = fetchPypi {
    pname = "mcp_for_blender";
    inherit version;
    hash = "sha256-CUyq3roNmk0XC5ON37M3t0rjnKDdKq24K/tvuTyL7Cc=";
  };

  build-system = with python3Packages; [
    setuptools
    wheel
  ];

  dependencies = with python3Packages; [
    mcp_1
    httpx
  ];

  pythonImportsCheck = [ "blender_mcp" ];

  # Path of the Blender addon inside this package, relative to its output.
  passthru.addonPath = "${python3Packages.python.sitePackages}/blender_mcp/bundled/addon.py";

  meta = {
    description = "Blender integration through the Model Context Protocol";
    homepage = "https://github.com/ahujasid/blender-mcp";
    license = lib.licenses.mit;
    mainProgram = "mcp-for-blender";
  };
}
