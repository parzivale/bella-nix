{
  lib,
  config,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.enable = false;
  nix = {
    settings = {
      secret-key-files = lib.mkDefault [config.age.secrets.deploy-key.path];
      experimental-features = "nix-command flakes";
      use-xdg-base-directories = true;
      substituters = [
        "https://nix-community.cachix.org"
        "https://nyx.chaotic.cx"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        (builtins.readFile ./secrets/deploy-key.pub)
      ];
    };
    optimise = lib.mkDefault {
      automatic = true;
      dates = "daily";
    };
    gc = lib.mkDefault {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than-7d";
    };
  };
}
