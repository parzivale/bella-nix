{self, ...}: {
  flake.modules.nixos.deployer = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    imports = with self.modules.nixos; [
      nh
      ssh
      git
      tailscale
      preservation
      signed-nix
    ];

    nix.settings.system-features = [
      "yubikey"
    ];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = "develop";
          mode = "0755";
        }
      ];
    };
  };
}
