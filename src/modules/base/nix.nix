{
  flake.modules.nixos.nix = {
    nixpkgs.config.allowUnfree = true;
    # documentation.nixos.enable = false;
    # documentation.man.enable = false;
    # documentation.enable = false;
    nix = {
      settings = {
        download-buffer-size = 268435456;
        experimental-features = "nix-command flakes";
        use-xdg-base-directories = true;
        substituters = [
          "https://nix-community.cachix.org"
          "https://nixos-apple-silicon.cachix.org"
          "https://playit-nixos-module.cachix.org"
        ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
          "playit-nixos-module.cachix.org-1:22hBXWXBbd/7o1cOnh+p0hpFUVk9lPdRLX3p5YSfRz4="
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
        options = "--delete-older-than 7d";
      };
    };
  };
}
