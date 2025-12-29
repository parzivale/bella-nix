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
  };
}
