{
  vars,
  config,
  ...
}: let
  user = vars.username;
in {
  home-mamanger = {
    users.${user} = {
      wayland.windowManager.mango = {
        enable = config.programs.mango.enable;
        settings = builtins.readFile ./mango.conf;
      };
    };
  };
}
