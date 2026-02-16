{
  flake.modules.nixos.nh = {config, ...}: {
    home-manager.users.${config.vars.username} = {
      programs = {
        nh.enable = true;
      };
    };
  };
}
