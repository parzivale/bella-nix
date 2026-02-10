{
  vars,
  pkgs,
  lib,
  config,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
    programs.home-manager.enable = false;
  };

  # Nixos anywhere is a fragile fickle thing that needs its own user who has a posix
  # complient user shell
  users.users.nixos-anywhere = {
    openssh.authorizedKeys.keyFiles = [../../common/secrets/yubikey_sshkey.pub];
    isNormalUser = true;
    hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
    extraGroups = ["wheel"];
  };
  services.openssh.settings.AllowUsers = ["nixos-anywhere"];

  services.getty.autologinUser = user;
  services.tailscale.enable = false;

  environment.systemPackages = with pkgs; [
    nixos-facter
    age
    age-plugin-fido2-hmac
    fzf
  ];

  preservation.enable = false;

  # No secrets allowed in bootstrap
  nix.settings.secret-key-files = [];

  system.stateVersion = "25.11";
}
