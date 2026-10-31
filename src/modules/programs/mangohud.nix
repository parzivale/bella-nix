{ inputs, ... }:
let
  # The same module for nixos and finix; `class` only picks which home-manager it imports.
  module =
    class:
    { config, ... }:
    let
      user = config.constants.username;
    in
    {
      imports = [ inputs.self.modules.${class}.home-manager ];

      home-manager.users.${user}.imports = [ inputs.self.modules.homeManager.mangohud ];
    };
in
{
  flake.modules.homeManager.mangohud = _: {
    programs.mangohud = {
      enable = true;
      settings = {
        fps = true;
        fps_metrics = [
          "avg"
          "0.01"
          "0.001"
        ]; # avg, 1% low, 0.1% low
        frametime = true;
        frame_timing_detailed = true; # min/max/current frametime for pacing
        cpu_stats = true;
        gpu_stats = true;
        vram = true;
        ram = true;
        gpu_temp = true;
        cpu_temp = true;
      };
    };
  };

  flake.modules.nixos.mangohud = module "nixos";
  flake.modules.finix.mangohud = module "finix";
}
