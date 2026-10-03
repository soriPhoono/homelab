# System Controls ipc for Noctalia v5+

Source: <https://docs.noctalia.dev/noctalia/ipc/system-controls/>

<!-- Verbatim upstream page: long code lines and site anchors are kept as-is. -->
<!-- markdownlint-disable MD001 MD013 MD025 MD051 -->

Retrieved: 2026-10-02

These commands are useful for media keys, compositor binds, scripts, and custom
widgets.

## OSD

| Action                 | Command       | Description                                           |
| ---------------------- | ------------- | ----------------------------------------------------- |
| Enable all OSD popups  | `osd-enable`  | Enable OSD popups for the running shell.              |
| Disable all OSD popups | `osd-disable` | Disable OSD popups and close any visible popup.       |
| Toggle all OSD popups  | `osd-toggle`  | Toggle OSD popups at runtime and print `on` or `off`. |

`osd-enable`, `osd-disable`, and `osd-toggle` apply only to the running shell
and never change the saved `[osd].enabled` setting. Turning OSDs off immediately
closes any visible popup. An explicit change to the saved OSD toggle cancels the
runtime override.

## Volume

| Action                   | Command         | Description                                                                  |
| ------------------------ | --------------- | ---------------------------------------------------------------------------- |
| Set output volume        | `volume-set 65` | Set output volume. Accepts `65`, `65%`, or normalized values such as `0.65`. |
| Raise output volume      | `volume-up`     | Raise output volume by the default step.                                     |
| Raise output by amount   | `volume-up 10`  | Raise output volume by a custom step.                                        |
| Lower output volume      | `volume-down`   | Lower output volume by the default step.                                     |
| Mute output              | `volume-mute`   | Toggle output mute.                                                          |
| Show volume OSD          | `volume-osd`    | Show the volume OSD at the current volume without changing it.               |
| Show volume OSD at value | `volume-osd 72` | Show the volume OSD at the given value without changing volume.              |

Default step is 5% when not specified. Output volume is clamped to 100% unless
`[audio] enable_overdrive = true`, which allows up to 150%. The same ceiling
applies to the value accepted by `volume-osd`.

## Microphone

| Action                | Command              | Description                                                         |
| --------------------- | -------------------- | ------------------------------------------------------------------- |
| Set mic volume        | `mic-volume-set 0.5` | Set microphone volume. Accepts normalized or percent values.        |
| Raise mic volume      | `mic-volume-up`      | Raise microphone volume by the default step.                        |
| Raise mic by amount   | `mic-volume-up 5%`   | Raise microphone volume by a custom step.                           |
| Lower mic volume      | `mic-volume-down`    | Lower microphone volume by the default step.                        |
| Mute mic              | `mic-mute`           | Toggle microphone mute.                                             |
| Show mic OSD          | `mic-volume-osd`     | Show the microphone OSD at the current volume without changing it.  |
| Show mic OSD at value | `mic-volume-osd 40%` | Show the microphone OSD at the given value without changing volume. |

`volume-osd` and `mic-volume-osd` never change the level. Called with no value
they show the current one, which suits a “show me the volume” bind. Called with
a value they show that value instead, for scripts that manage volume outside
Noctalia such as an MPD volume sync. Both start on the focused output when
`[osd].follow_focused_output` is enabled and stay there until the popup
disappears; otherwise they appear on the monitors configured under
`[osd].monitors`. Both reflect the real mute state of the device.

## Brightness

| Action                   | Command                    | Description                                                                                                                 |
| ------------------------ | -------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Set current brightness   | `brightness-set 65`        | Set brightness on the current monitor.                                                                                      |
| Set one monitor          | `brightness-set DP-1 0.65` | Set brightness for a specific monitor or monitor selector.                                                                  |
| Set all monitors         | `brightness-set * 40%`     | Set brightness on every monitor.                                                                                            |
| Raise current brightness | `brightness-up`            | Raise brightness by the default step.                                                                                       |
| Raise one monitor        | `brightness-up DP-1 10`    | Raise brightness for one monitor.                                                                                           |
| Lower all monitors       | `brightness-down * 5%`     | Lower brightness on every monitor.                                                                                          |
| Show brightness OSD      | `brightness-osd 72`        | Show the brightness OSD at the given value without changing brightness. Useful when an external script controls brightness. |

Targets can be `current`, `all`, `*`, a monitor connector name such as `eDP-1`
or `DP-1`, or a monitor selector token. Values accept normalized `0.0` to `1.0`
or percentage form such as `65`, `65%`, and `5%`.

`brightness-osd` takes a value only - unlike `brightness-set`, it has no monitor
target. The OSD starts on the focused output when `[osd].follow_focused_output`
is enabled and stays there until the popup disappears; otherwise it appears on
whichever monitors are configured under `[osd].monitors`.

## Night light

| Action             | Command                   | Description                                          |
| ------------------ | ------------------------- | ---------------------------------------------------- |
| Enable schedule    | `nightlight-enable`       | Enable scheduled night light.                        |
| Disable schedule   | `nightlight-disable`      | Disable scheduled night light.                       |
| Toggle schedule    | `nightlight-toggle`       | Toggle scheduled night light.                        |
| Toggle forced mode | `nightlight-force-toggle` | Force night light on or return to schedule behavior. |

## Wireless

| Action                | Command             | Description                     |
| --------------------- | ------------------- | ------------------------------- |
| Enable Wi-Fi          | `wifi-enable`       | Turn the Wi-Fi radio on.        |
| Disable Wi-Fi         | `wifi-disable`      | Turn the Wi-Fi radio off.       |
| Toggle Wi-Fi          | `wifi-toggle`       | Toggle the Wi-Fi radio.         |
| Show Wi-Fi status     | `wifi-status`       | Print `on` or `off`.            |
| Enable Bluetooth      | `bluetooth-enable`  | Turn the Bluetooth adapter on.  |
| Disable Bluetooth     | `bluetooth-disable` | Turn the Bluetooth adapter off. |
| Toggle Bluetooth      | `bluetooth-toggle`  | Toggle the Bluetooth adapter.   |
| Show Bluetooth status | `bluetooth-status`  | Print `on` or `off`.            |

Wi-Fi and Bluetooth IPC commands show a short OSD when they change the state.

## Caffeine

| Action           | Command            | Description                         |
| ---------------- | ------------------ | ----------------------------------- |
| Enable caffeine  | `caffeine-enable`  | Prevent idle actions while enabled. |
| Disable caffeine | `caffeine-disable` | Allow idle actions again.           |
| Toggle caffeine  | `caffeine-toggle`  | Switch caffeine on or off.          |

Caffeine IPC commands show a short OSD when they change the state.

## Power profile

Requires `org.freedesktop.UPower.PowerProfiles` (same as the Control Center home
shortcut). Profile ids come from the compositor/session; common values are
`performance`, `balanced`, and `power-saver`.

When another app or an IPC command changes the active profile, Noctalia shows a
short OSD with the active mode’s icon and profile name. Profile changes made
through Noctalia’s UI update the UI and fire hooks without showing extra OSD
feedback.

| Action              | Command              | Description                                                                                                                                                                              |
| ------------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Set power profile   | `power-set balanced` | Activate the named profile. If the service reports a profile list, the name must match one of those entries exactly.                                                                     |
| Cycle power profile | `power-cycle`        | Switch to the next profile in UPower’s ordered list (same order as the bar power widget and control center shortcut). Wraps from the last profile back to the first. Takes no arguments. |

## Monitor power

| Action            | Command    | Description        |
| ----------------- | ---------- | ------------------ |
| Turn monitors on  | `dpms-on`  | Turn monitors on.  |
| Turn monitors off | `dpms-off` | Turn monitors off. |
