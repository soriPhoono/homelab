# TODO

These are the tasks that are intended for future development goals

- [ ] Configure hermes agent
  - [ ] configure local matrix server for bot accounts
- [ ] Test vr support on desktop
- [ ] Finish implementing better security hardening
- [ ] Implement impermenance on all nixos devices
- [ ] Recreate the neovim configuration system that allows for creation of nixvim customized neovim editors
- [ ] Recreate nix on droid configuration system as second type of system

## MCP Infrastructure — Server Issues & Fixes

### office/pdf — Server crash on write operations [UPSTREAM BUG]

- `pdf_edit_metadata` causes an internal `ValueError` that crashes the
  `office/pdf` MCP server entirely, putting it into a ~60s backoff for all
  subsequent calls.
- `pdf_add_bookmark` and other write-heavy ops fail during the recovery window.
- **Root cause:** The `pdf-edit-mcp` v0.2.0 server uses FastMCP with an
  `engine_guard()` context manager that catches all exceptions and converts
  them to `ToolError`. However, `pikepdf.open_metadata()` /
  `meta[xmp_key] = value` in `pdf_edit_engine.wrapper.edit_metadata()` can
  raise `ValueError` from pikepdf's XMP metadata writer in edge cases (e.g.
  non-string metadata values, namespace violations). These should be caught
  by the `except Exception` in `engine_guard()`, so if the server is crashing
  rather than returning a ToolError, it may be a FastMCP-level serialization
  issue or a version mismatch in the installed `pdf-edit-engine`.
- **Status:** Investigate whether upgrading `pdf-edit-mcp` / `pdf-edit-engine`
  resolves the crash, or file issue at: https://github.com/AryanBV/pdf-edit-mcp
- **Fix:** Either pin a known-good version, or report the crash with a
  reproducer to the upstream project.
