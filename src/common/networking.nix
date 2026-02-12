# Common networking options (no where better to put these)
{lib, ...}: {
  # Needed for the onboarding script

  # Not needed but makes tailscale magic dns better
  services.resolved.enable = lib.mkDefault true;

  networking.nameservers = ["1.1.1.1" "8.8.8.8"];
}
