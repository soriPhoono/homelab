_: _final: prev: let
  # Wrap @neuraforge/office-mcp to inject the missing Python bridge scripts
  # that the JS code expects but the upstream npm package doesn't ship.
  #
  # The JS files call: execFileSync('python3', [BRIDGE, cmd, JSON.stringify(args)])
  # where BRIDGE is path.join(__dirname, 'docx_bridge.py') or 'pptx_bridge.py'
  #
  # Solution: Use a Node.js --loader to patch the source at import time,
  # redirecting BRIDGE to our bridge scripts directory.
  pythonWithDeps = prev.python3.withPackages (ps: [
    ps.python-docx
    ps.python-pptx
  ]);

  # Create a directory with the bridge scripts
  bridgeScripts = prev.runCommand "office-mcp-bridge-scripts" {} ''
    mkdir -p $out
    cp ${./office-mcp/docx_bridge.py} $out/docx_bridge.py
    cp ${./office-mcp/pptx_bridge.py} $out/pptx_bridge.py
    chmod +x $out/*.py
  '';

  # Create a Node.js module hook that patches the BRIDGE path at import time
  # Both files must be in the same directory so register() can resolve the hook
  bridgeLoaderDir = prev.runCommand "office-mcp-bridge-loader" {} ''
    mkdir -p $out

    cat > $out/bridge-loader.mjs << 'LOADER'
    import { register } from 'node:module';
    import { pathToFileURL } from 'node:url';
    register('./bridge-hook.mjs', import.meta.url);
    LOADER

    cat > $out/bridge-hook.mjs << 'HOOK'
    const BRIDGE_SCRIPTS_DIR = process.env.BRIDGE_SCRIPTS_DIR;

    export async function load(url, context, nextLoad) {
      // Only patch office-mcp files
      if (BRIDGE_SCRIPTS_DIR && (url.includes('/docx.js') || url.includes('/pptx.js'))) {
        const result = await nextLoad(url, context);
        let source = result.source.toString();

        // Replace the BRIDGE path construction
        source = source.replace(
          /const BRIDGE = path\.join\(path\.dirname\(new URL\(import\.meta\.url\)\.pathname\), '([^']+)'\);/g,
          "const BRIDGE = process.env.BRIDGE_SCRIPTS_DIR + '/$1';"
        );

        return {
          format: 'module',
          source,
          shortCircuit: true,
        };
      }

      return nextLoad(url, context);
    }
    HOOK
  '';

  # Create wrapper scripts
  officeMcp =
    prev.runCommand "office-mcp-1.0.1-patched" {
      nativeBuildInputs = [prev.makeWrapper prev.nodejs];
      buildInputs = [pythonWithDeps bridgeScripts bridgeLoaderDir];
    } ''
      mkdir -p $out/bin

      # Create wrapper scripts for each mode
      for mode in pptx docx xlsx; do
        makeWrapper ${prev.nodejs}/bin/npx $out/bin/office-mcp-$mode \
          --set BRIDGE_SCRIPTS_DIR "${bridgeScripts}" \
          --set NODE_OPTIONS "--import ${bridgeLoaderDir}/bridge-loader.mjs" \
          --prefix PATH : ${pythonWithDeps}/bin \
          --add-flags "-y @neuraforge/office-mcp --$mode"
      done
    '';
in {
  office-mcp = officeMcp;
}
