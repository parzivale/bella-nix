{
  flake.modules.nixos.nix =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;
      # documentation.nixos.enable = false;
      # documentation.man.enable = false;
      # documentation.enable = false;
      nix = {
        package = pkgs.nixVersions.latest;
        settings = {
          download-buffer-size = 268435456;
          experimental-features = "nix-command flakes";
          use-xdg-base-directories = true;
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixos-apple-silicon.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
            (builtins.readFile ../../secrets/master/nix-deploy/deploy-key.pub)
          ];
        };
        optimise = {
          automatic = true;
          dates = "daily";
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };
    };
}
