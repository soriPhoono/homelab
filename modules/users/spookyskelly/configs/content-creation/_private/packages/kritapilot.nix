# KritaPilot: an MCP server that drives Krita through a loopback bridge opened
# by its Krita plugin. The plugin ships inside the package at
# kritapilot/krita_plugin; passthru.pluginPath locates it.
#
# The plugin's over-the-air updater is switched off, the same patch upstream
# applies to the copy bundled with Krita: it would try to rewrite the
# read-only plugin directory, and Nix pins the version instead.
{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "kritapilot";
  version = "1.0.20";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-X3C8UPPQhoBaa7WSMDuNImQLDh0m/HYeYuFbGeRC4oM=";
  };

  postPatch = ''
    substituteInPlace plugin/pykrita/kritapilot_plugin/extension.py \
      --replace-fail "UPDATER_ENABLED = True" "UPDATER_ENABLED = False"
  '';

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    mcp_1
    uvicorn
  ];

  pythonImportsCheck = [ "kritapilot" ];

  # Directory holding kritapilot_plugin/ and kritapilot_plugin.desktop,
  # relative to this package's output.
  passthru.pluginPath = "${python3Packages.python.sitePackages}/kritapilot/krita_plugin";

  meta = {
    description = "Krita MCP server and AI assistant";
    homepage = "https://github.com/jowinjohnchemban/kritapilot";
    license = lib.licenses.mit;
    mainProgram = "kritapilot";
  };
}
