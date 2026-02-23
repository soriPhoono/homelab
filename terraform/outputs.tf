output "nix_store_path" {
  value       = data.external.nix_build.result.path
  description = "The local Nix store path of the built LXC tarball"
}
