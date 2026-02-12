{vars, ...}: {
  flakes.modules.bella.nh = {
    home-manager.users.${vars.username} = {
      programs = {
        nh.enable = true;
      };
    };
  };
}
