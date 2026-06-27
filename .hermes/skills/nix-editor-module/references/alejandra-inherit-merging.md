# alejandra formatting quirks

Alejandra (Nix formatter, used via `nix fmt`) is purely a syntactic
formatter and should NOT change semantics. However, in practice:

## Observed: inherit lines consolidated

When a file has:

```nix
programs.zed-editor = {
  enable = true;
  inherit (cfg) package;
  # unrelated comment
  inherit (cfg) extensions userSettings;
};
```

And another section has:

```nix
home.packages = cfg.extraPackages;
```

Alejandra may reformat to:

```nix
programs.zed-editor = {
  enable = true;
  inherit (cfg) package extraPackages;
  inherit (cfg) extensions userSettings;
};
```

This silently MOVES the `extraPackages` reference into the `programs.zed-editor`
block, even though `programs.zed-editor` has no `extraPackages` option.

## Defense

Always `git diff` after `nix fmt` to verify no semantic changes were
introduced. Check that:

- `inherit` lines only reference attributes valid for that option group
- No `home.packages` assignments disappear
- No values move between unrelated config blocks

## Key insight

Alejandra can merge `inherit` lines when it detects the same source
(`cfg`) being used across different sections. If `home.packages` references
`cfg.extraPackages` and `programs.zed-editor` references `cfg.package`,
alejandra may combine them into a single `inherit (cfg) package extraPackages;`
line inside `programs.zed-editor`, which is WRONG.
