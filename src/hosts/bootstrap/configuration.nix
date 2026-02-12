{
  self,
  vars,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  inputs = with self.modules.bella; [
    user
    openssh
    stylix
    avahi
    systemd-boot
  ];

  home-manager.users.${user} = {
    home = {
      stateVersion = "25.11";
      packages = with pkgs; [
        nixos-facter
        age
        age-plugin-fido2-hmac
      ];
    };
  };

  # Nixos anywhere is a fragile fickle thing that needs its own user who has a posix
  # complient user shell
  users.users.nixos-anywhere = {
    openssh.authorizedKeys.keyFiles = [../../secrets/yubikey/yubikey_sshkey.pub];
    isNormalUser = true;
    hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
    extraGroups = ["wheel"];
  };

  services.openssh.settings.AllowUsers = ["nixos-anywhere"];

  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  services.getty.autologinUser = user;

  system.stateVersion = "25.11";
}
