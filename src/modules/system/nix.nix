let
  # The same answers either way: where to fetch from, what to trust, how the
  # daemon should behave. Only the option paths differ.
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

  settings = {
    download-buffer-size = 268435456;
    experimental-features = "nix-command flakes";
    use-xdg-base-directories = true;
    inherit substituters trusted-public-keys;
  };
in
{
  flake.modules.nixos.nix =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfree = true;

      nix = {
        package = pkgs.nixVersions.latest;
        inherit settings;

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

  flake.modules.finix.nix =
    { pkgs, modules, ... }:
    {
      imports = [
        modules.nix-daemon
        modules.nix-collect-garbage
      ];

      nixpkgs.config.allowUnfree = true;

      services.nix-daemon = {
        enable = true;
        package = pkgs.nixVersions.latest;

        settings = settings // {
          # `nix.optimise` on the nixos side, which is a timer running
          # `nix-store --optimise`. The daemon can do it as it writes instead,
          # which is the closest thing finix has and arguably the better one.
          auto-optimise-store = true;
        };
      };

      # `nix.gc` over there. The interval takes the same words; the flags that
      # were `options` are a list here.
      services.nix-collect-garbage = {
        enable = true;
        interval = "weekly";
        extraArgs = [
          "--delete-older-than"
          "7d"
        ];
      };
    };
}
