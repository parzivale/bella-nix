{inputs, ...}: {
  flake.modules.homeManager.wireshark = {pkgs, ...}: {
    home.packages = [pkgs.wireshark];
  };

  flake.modules.nixos.wireshark = {config, ...}: let
    user = config.systemConstants.username;
  in {
    programs.wireshark.enable = true;
    users.users.${user}.extraGroups = ["wireshark"];

    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.wireshark];
  };
}
