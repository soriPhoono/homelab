# Helpers for writing Hyprland Lua settings through Home Manager.
#
# Each value renders as one `hl.bind(...)` call: `_args` becomes a Lua
# multi-argument call and `mkLuaInline` passes the dispatcher through as a
# raw Lua expression.
{ lib }:
rec {
  lua = lib.generators.mkLuaInline;
  toLua = lib.generators.toLua { };

  bind = keys: dispatcher: {
    _args = [
      keys
      (lua dispatcher)
    ];
  };

  bindWith = keys: dispatcher: opts: {
    _args = [
      keys
      (lua dispatcher)
      opts
    ];
  };

  exec = command: "hl.dsp.exec_cmd(${toLua command})";

  # Every direction is reachable from both the vim keys and the arrow keys.
  directions = [
    {
      keys = [
        "h"
        "left"
      ];
      dir = "l";
      x = -1;
      y = 0;
    }
    {
      keys = [
        "j"
        "down"
      ];
      dir = "d";
      x = 0;
      y = 1;
    }
    {
      keys = [
        "k"
        "up"
      ];
      dir = "u";
      x = 0;
      y = -1;
    }
    {
      keys = [
        "l"
        "right"
      ];
      dir = "r";
      x = 1;
      y = 0;
    }
  ];

  # One bind per key of every direction: f receives the direction and a key.
  forDirections = f: lib.concatMap (d: map (key: f d key) d.keys) directions;
}
