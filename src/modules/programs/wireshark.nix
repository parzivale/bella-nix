_: {
  flake.modules.nixos.wireshark =
    { pkgs, config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };
      users.users.${user}.extraGroups = [ "wireshark" ];
    };
}
