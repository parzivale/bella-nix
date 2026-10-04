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
    # A list rather than the whitespace-separated string this was: nixpkgs'
    # `nix.settings.experimental-features` is `listOf str` now, and the coercion
    # from a string is gone. finix's freeform `configType` takes either and
    # renders a list with `toString`, so the nix.conf line is the same on both.
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    use-xdg-base-directories = true;
    inherit substituters trusted-public-keys;
  };
in
{
  flake.modules.nixos.nix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # A merging seam in front of `nixpkgs.config.permittedInsecurePackages`,
      # because that option cannot take two definitions. `nixpkgs.config` is an
      # opaque type whose merge is `recursiveUpdate`, so a list under it is
      # replaced rather than concatenated: the second module to name an insecure
      # package silently unpermits the first one's, and nothing says so - the
      # error that comes back names the package whose entry lost, which looks
      # like the entry was never written.
      #
      # Two modules want one each now - the Discord bridge's olm and kanidm's own
      # EOL pin - so they write here and this assembles them, the same shape as
      # `reverseProxy` being declared once and written by whoever has a vhost.
      #
      # A definition here must not be computed from `pkgs`: this is read while
      # the package set is being constructed, so anything reaching back into it
      # closes a loop. Package *names* are what this takes, which is what
      # nixpkgs matches against anyway.
      options.permittedInsecurePackages = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [ "olm-3.2.16" ];
        description = ''
          Package names, with versions, to forward to
          {option}`nixpkgs.config.permittedInsecurePackages`. Unlike that option
          this one merges, so any number of modules may contribute.
        '';
      };

      config = {
        nixpkgs.config = {
          allowUnfree = true;
          inherit (config) permittedInsecurePackages;
        };

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
