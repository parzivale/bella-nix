{
  vars,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
    programs.home-manager.enable = false;
  };

  users.users.nixos-anywhere = {
    openssh.authorizedKeys.keyFiles = [../../common/secrets/yubikey_sshkey.pub];
    isNormalUser = true;
    hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
    extraGroups = ["wheel"];
  };

  services.getty.autologinUser = user;
  services.tailscale.enable = false;
  services.openssh.settings.AllowUsers = ["nixos-anywhere"];
  environment.systemPackages = [
    pkgs.nixos-facter
    pkgs.age
    pkgs.age-plugin-fido2-hmac
    pkgs.fzf
  ];

  programs.ssh.startAgent = true;
  services.avahi.enable = true;

  networking.nameservers = ["1.1.1.1" "8.8.8.8"];
  system.stateVersion = "25.11";
}
