{ inputs, ... }:
let
  # The same list either way - each of these publishes both classes, so the
  # profile is the set of names and the class is which namespace they come from.
  # The comments say what each group is for rather than what it contains.
  modules = [
    "localization"
    "stylix"

    # CLI apps that only make sense with a display
    "iamb"
    "direnv"
    "github"

    # compositor + GUI apps
    "niri"
    "wezterm"
    "lazygit"
    "yazi"
    "zen"
    "fuzzel"
    "_1password"
    "claude"
    "spotify-player"
    "prismlauncher"
    "blender"

    # desktop hardware/services
    "xdg-desktop-portal-termfilepickers"
    "keyring"
    "pipewire"
    "bluetooth"
    "network"
    "mako"
    "swayidle"
    "avahi"
    "printing"
    "boot"
    "kernel"
    "powertop"
  ];

  from = class: map (name: inputs.self.modules.${class}.${name}) modules;
in
{
  flake.modules.nixos.desktop.imports = from "nixos";
  flake.modules.finix.desktop.imports = from "finix";
}
