{ inputs, ... }:
{
  flake.modules.homeManager.mangohud = _: {
    programs.mangohud = {
      enable = true;
      settings = {
        fps = true;
        frametime = true;
        cpu_stats = true;
        gpu_stats = true;
        vram = true;
        ram = true;
        gpu_temp = true;
        cpu_temp = true;
      };
    };
  };

  flake.modules.nixos.mangohud =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.mangohud ];
    };
}
