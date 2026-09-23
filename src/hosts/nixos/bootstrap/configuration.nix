{ inputs }:
{
  config,
  pkgs,
  ...
}:
let
  user = config.systemConstants.username;
in
{
  networking.hostName = "bootstrap";

  imports = with inputs.self.modules.nixos; [
    nixos
    secrets
    home-manager
    openssh
    stylix
    avahi
    boot
  ];

  home-manager.users.${user} = {
    home = {
      stateVersion = "25.11";
      packages = with pkgs; [
        nixos-facter
        age
        age-plugin-fido2-hmac
        inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
      ];
    };
  };

  # Nixos anywhere is a fragile fickle thing that needs its own user who has a posix
  # complient user shell
  users.users.nixos-anywhere = {
    openssh.authorizedKeys.keyFiles = [
      ../../../secrets/yubikey/yubikey_sshkey_usba.pub
      ../../../secrets/yubikey/yubikey_sshkey_usbc.pub
    ];
    isNormalUser = true;
    hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
    extraGroups = [ "wheel" ];
  };

  hardware.enableAllFirmware = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../../../secrets/yubikey/yubikey_sshkey_usba.pub
    ../../../secrets/yubikey/yubikey_sshkey_usbc.pub
  ];
  services = {
    openssh.settings = {
      PermitRootLogin = "prohibit-password";
      AllowUsers = [
        "nixos-anywhere"
        "root"
      ];
    };
    getty.autologinUser = user;
  };

  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  system.stateVersion = "25.11";
}
