{ inputs, ... }:
{
  flake.modules.nixos.wireshark =
    { pkgs, config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      imports = [ inputs.self.modules.nixos.user ];

      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };
      users.users.${user}.extraGroups = [ "wireshark" ];
    };
}
