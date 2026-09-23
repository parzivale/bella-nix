{
  flake.modules.nixos.deployer =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.constants.username;
    in
    {
      nix.settings.system-features = [
        "yubikey"
      ];

      state.preserve.users.${user} = {
        directories = [
          {
            directory = "develop";
            mode = "0755";
          }
        ];
      };
    };
}
