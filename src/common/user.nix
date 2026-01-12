{
  pkgs,
  inputs,
  config,
  vars,
  ...
}: let
  user = vars.username;
in {
  # Declaritivly manage users
  services.userborn.enable = true;

  users = {
    mutableUsers = false;
    users.${user} = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.user-password.path;
      extraGroups = ["wheel"];
      uid = vars.uid;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${user} = {
      programs = {
        home-manager.enable = true;
      };
      home = {
        username = "${user}";
      };
      xdg = {
        enable = true;
        userDirs = {
          # Enable this on desktop machines
          # via home-manager.users.${vars.username}.xdg.userDirs.enable = true
          createDirectories = true;
        };
      };
    };
  };
}
