/**
  Whether `path` sits on a filesystem other than root. Such a path already
  outlives the root reset of `core.impermanence` and must not be declared
  under `environment.persistence` as well: that would bind-mount over it.
*/
{ lib, config }:
path:
lib.any (
  fs: fs.mountPoint != "/" && (path == fs.mountPoint || lib.hasPrefix "${fs.mountPoint}/" path)
) (lib.attrValues config.fileSystems)
