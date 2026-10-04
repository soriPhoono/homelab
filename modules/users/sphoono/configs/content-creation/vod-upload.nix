{
  # Moves finished OBS recordings to Google Drive, where the n8n pipeline on
  # sphoono-vps picks them up. Drive is the long-term backup, so the local
  # copy is deleted once rclone has verified the upload.
  #
  # The `gdrive` remote is created imperatively with `rclone config`; its
  # token stays in ~/.config/rclone/ and is never managed by Nix.
  den.aspects.sphoono.content-creation.homeManager =
    { config, pkgs, ... }:
    let
      remote = "gdrive:Work/Content Creation/vods";
    in
    {
      home.packages = [ pkgs.rclone ];

      systemd.user = {
        services.vod-upload = {
          Unit = {
            Description = "Move finished recordings to Google Drive";
            ConditionPathExists = "%h/.config/rclone/rclone.conf";
          };
          Service = {
            Type = "oneshot";
            # OBS rewrites a file for as long as it records, so anything
            # untouched for 5 minutes is finished. Hybrid MP4 needs no remux.
            ExecStart = ''${pkgs.rclone}/bin/rclone move ${config.xdg.userDirs.videos} "${remote}" --max-depth 1 --include "*.mp4" --min-age 5m --transfers 1'';
            Nice = 19;
            IOSchedulingClass = "idle";
          };
        };

        timers.vod-upload = {
          Unit.Description = "Periodically move finished recordings to Google Drive";
          Timer = {
            OnBootSec = "5m";
            OnUnitInactiveSec = "5m";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    };
}
