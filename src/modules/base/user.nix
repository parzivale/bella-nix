{
  lib,
  vars,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  flake.modules.bella.user = {
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
  };
}
