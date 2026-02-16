{
  flake.modules.nixos.nh = {config, ...}: {
    home-manager.users.${config.systemConstants.username} = {
      programs = {
        nh.enable = true;
      };
    };
  };
}
