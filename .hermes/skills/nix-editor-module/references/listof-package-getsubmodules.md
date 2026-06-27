# listOf package → getSubModules in NixOS+HM submodule

## Symptoms

Assigning `cfg.extraPackages` (declared via overlay-defined `mkEditor` with
`type = with types; listOf package`) to any other `listOf package` option
inside a NixOS+home-manager submodule context fails with:

```
error: attribute 'getSubModules' missing
at lib/types.nix:751:23
```

This happens only when home-manager runs embedded as a NixOS module
(`home-manager.users.<name>`) — standalone `home-manager` configurations
evaluate fine.

## Systems affected

NixOS systems with integrated home-manager (HM as NixOS module).
Standalone home-manager configs are NOT affected.

## Root cause

The `fixupOptionType` function in the module system checks
`opt.type.getSubModules or null == null` for every option. When the type is
`listOf package`:

1. `listOf`'s `getSubModules` reads `elemType.getSubModules`
1. `package` (i.e. `types.derivation`) inherits `getSubModules` from
   `types.attrs` — in theory it exists
1. But when the type is declared with `with types; listOf package` inside
   an overlay function (`_final: prev: { homelab = ... }`), the `with`
   scope resolution in Nix does NOT correctly resolve `package` to
   `types.package` in all contexts. The inner type captured by `listOf`
   ends up without `getSubModules`.

The same type declaration (`type = with types; listOf package;`) works when
the option is declared inline in the consumer module but fails when declared
via a function call (`mkEditor`) in an overlay. The `with types;` scope
resolution behaves differently in overlay context vs module context.

## Fix

**Use fully-qualified types in the overlay.** Replace:

```nix
# BROKEN in overlay context:
type = with types; listOf package;
```

With:

```nix
# WORKS in overlay context:
type = types.listOf types.package;
```

This bypasses the `with` scope resolution issue entirely. The explicit path
`types.listOf types.package` resolves correctly regardless of context.

All other attempted workarounds (identity maps, flattens, concatenations,
conditional wrappers) FAIL because they only operate on the *value* side —
the root cause is in the *type declaration*, not the value assignment.

## Verification

After the fix, run with `--refresh` to clear any cached failures:

```bash
nix flake check --refresh
```

The affected NixOS configurations should now pass.
