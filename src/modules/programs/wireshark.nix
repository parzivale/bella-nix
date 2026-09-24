{ inputs, ... }:
let
  # Who is allowed to capture. dumpcap is what actually opens the interface, so
  # the group gates the wrapper around it rather than wireshark itself.
  shared =
    class:
    { pkgs, config, ... }:
    {
      imports = [ inputs.self.modules.${class}.user ];

      programs.wireshark = {
        enable = true;
        package = pkgs.wireshark;
      };

      users.users.${config.constants.username}.extraGroups = [ "wireshark" ];
    };
in
{
  flake.modules.nixos.wireshark = shared "nixos";

  flake.modules.finix.wireshark =
    { modules, ... }:
    {
      imports = [
        modules.wireshark
        (shared "finix")
      ];
    };
}
