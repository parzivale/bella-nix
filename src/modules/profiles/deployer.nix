{self, ...}: {
  flake.modules.nixos.deployer = {config, ...}: let
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

    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = "bella-nix";
        }
      ];
    };
  };
}
