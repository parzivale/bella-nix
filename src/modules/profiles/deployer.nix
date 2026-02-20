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

    home-manager.users.${user}.home.packages = [pkgs.deploy-rs];

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = "bella-nix";
        }
      ];
    };
  };
}
