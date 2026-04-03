let
  sphoono = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsLDpds7sJGuczBvZEIkqEBwjdk22MbiML/WYzHwzkT Personal Key";
in {
  "secrets/gemini_api_key.age".publicKeys = [sphoono];
  "secrets/codestral_api_key.age".publicKeys = [sphoono];
}
