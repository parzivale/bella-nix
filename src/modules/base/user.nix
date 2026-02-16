{
  flake.modules.nixos.user = {
    config,
    pkgs,
    ...
  }: let
    user = config.vars.username;
  in {
    # Declaritivly manage users
    services.userborn.enable = true;

    users = {
      mutableUsers = false;
      users = {
        ${user} = {
          openssh.authorizedKeys.keyFiles = [../../secrets/yubikey/yubikey_sshkey.pub];
          isNormalUser = true;
          hashedPassword = "$y$j9T$3SYXqLHQFhpwfTY8BHXmw.$cQGsYVD7CIWC22AJu1sX8qg4Po8Cyd00KzL9mAXa5F7";
          extraGroups = ["wheel" "networkmanager"];
          uid = config.vars.uid;
          shell = pkgs.nushell;
        };
      };
    };
  };
}
