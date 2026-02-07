{
  lib,
  vars,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  # Declaritivly manage users
  services.userborn.enable = true;

  users = {
    mutableUsers = false;
    users = {
      ${user} = {
        openssh.authorizedKeys.keyFiles = [./secrets/yubikey_sshkey.pub];
        isNormalUser = true;
        hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
        extraGroups = ["wheel" "networkmanager"];
        uid = vars.uid;
        shell = pkgs.nushell;
      };
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} = {
      programs = {
        home-manager.enable = lib.mkDefault true;
      };
      home = {
        username = "${user}";
      };
      xdg = {
        enable = true;
        userDirs = {
          # Enable this on desktop machines
          # via home-manager.users.${vars.username}.xdg.userDirs.enable = true
          enable = lib.mkDefault true;
          createDirectories = true;
        };
      };
    };
  };
}
