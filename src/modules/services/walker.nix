{
  flake.modules.nixos.walker = {config, ...}: let
    user = config.systemConstants.username;
  in {
    nix.settings = {
      extra-substituters = ["https://walker.cachix.org" "https://walker-git.cachix.org"];
      extra-trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM=" "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="];
    };

    home-manager.users.${user}.programs.walker = {
      enable = true;
      runAsService = true;
      config.theme = "default";
    };
  };
}
