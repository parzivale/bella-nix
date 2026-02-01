{
  vars,
  pkgs,
  inputs,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
  };

  users.users.nixos-anywhere = {
    openssh.authorizedKeys.keyFiles = [./secrets/yubikey_sshkey.pub];
    isNormalUser = true;
    hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
    extraGroups = ["wheel"];
    uid = 1001;
  };

  services.getty.autologinUser = user;

  environment.systemPackages = [
    pkgs.nixos-facter
    pkgs.age
    pkgs.age-plugin-fido2-hmac
    inputs.disktui.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.fzf
  ];

  programs.ssh.startAgent = true;
  services.avahi.enable = true;

  networking.nameservers = ["1.1.1.1"];
  system.stateVersion = "25.11";
}
