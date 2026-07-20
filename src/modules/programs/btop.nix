{ inputs, ... }:
{
  flake.modules.homeManager.btop = _: {
    programs.btop.enable = true;
  };

  flake.modules.nixos.btop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.systemConstants.username;
      cfg = config.btop.gpu;

      # btop numbers its GPU boxes by detection order, not by vendor, so the box
      # list is purely a function of how many backends are enabled.
      gpuCount = lib.count (x: x) [
        cfg.nvidia
        cfg.amd
      ];
      gpuBoxes = lib.genList (i: "gpu${toString i}") gpuCount;
    in
    {
      options.btop.gpu = {
        nvidia = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            NVIDIA GPU monitoring in btop. Adds no closure weight: btop dlopens
            libnvidia-ml.so from /run/opengl-driver/lib at runtime, so this only
            sets autoAddDriverRunpath.
          '';
        };

        amd = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            AMD GPU monitoring in btop. Opt-in because it rpaths in rocm-smi,
            which costs roughly 178MB of closure.
          '';
        };
      };

      config = {
        home-manager.users.${user} = {
          imports = [ inputs.self.modules.homeManager.btop ];

          programs.btop = {
            package = pkgs.btop.override {
              cudaSupport = cfg.nvidia;
              rocmSupport = cfg.amd;
            };

            # btop.conf is a read-only store symlink, so the in-app box toggle
            # (key 5) cannot persist — the boxes have to be declared here.
            settings.shown_boxes = lib.concatStringsSep " " (
              [
                "cpu"
                "mem"
                "net"
                "proc"
              ]
              ++ gpuBoxes
            );
          };
        };
      };
    };
}
