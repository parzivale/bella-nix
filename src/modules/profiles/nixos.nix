{ inputs, ... }:
{
  # What every NixOS host of mine wants and no finix host can use: a login
  # account, nix daemon settings, DNS. It lives here rather than in `base`
  # because base is class-neutral, and here rather than in the flake's host
  # wrapper because a host should say what it is rather than be handed it.
  flake.modules.nixos.nixos = {
    imports = with inputs.self.modules.nixos; [
      user
      nix
      systemd-resolved
    ];
  };
}
