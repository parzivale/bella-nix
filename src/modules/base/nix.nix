{
  flake.modules.nixos.nix = {
    nixpkgs.config.allowUnfree = true;
    documentation.nixos.enable = false;
    documentation.man.enable = false;
    documentation.enable = false;
    nix = {
      settings = {
        experimental-features = "nix-command flakes";
        use-xdg-base-directories = true;
        substituters = [
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          (builtins.readFile ../../secrets/nix-deploy/deploy-key.pub)
        ];
      };
      optimise = {
        automatic = true;
        dates = "daily";
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than-7d";
      };
    };
  };
}
