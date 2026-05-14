{moduleWithSystem, ...}: {
  flake.modules.nixos.deploy-user = moduleWithSystem ({inputs', ...}: {pkgs, ...}: let
    activate = "${inputs'.deploy-rs.packages.deploy-rs}/bin/activate";
  in {
    users.users.deploy = {
      isSystemUser = true;
      group = "deploy";
      shell = pkgs.bash;
      openssh.authorizedKeys.keyFiles = [
        ../../secrets/yubikey/yubikey_sshkey_usbc.pub
        ../../secrets/yubikey/yubikey_sshkey_usba.pub
      ];
    };
    users.groups.deploy = {};

    services.openssh.settings.AllowUsers = ["deploy"];

    security.sudo.extraRules = [
      {
        users = ["deploy"];
        commands = [
          {
            command = "${activate} *";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  });
}
