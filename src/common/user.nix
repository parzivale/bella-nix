{
  nixpkgs,
  inputs,
  config,
  vars,
  ...
}: {
  # Declaritivly manage users
  services.userborn.enable = true;

  users = {
    mutableUsers = false;
    users.${vars.user} = {
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.user-password.path;
      extraGroups = ["wheel"];
      uid = vars.uid;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${vars.user} = {
      programs = {
        home-manager.enable = true;
      };
      home = {
        username = "${vars.user}";
      };
      xdg = {
        enable = true;
        userDirs = {
          # Enable this on desktop machines
          # via home-manager.users.${vars.user}.xdg.userDirs.enable = true
          createDirectories = true;
        };
      };
    };
  };
}
