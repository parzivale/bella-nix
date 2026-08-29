{
  flake.modules.nixos.secrets =
    {
      config,
      pkgs,
      ...
    }:
    let
      user = config.systemConstants.username;
    in
    {
      home-manager.users.${user}.home = {
        packages = with pkgs; [
          age
          age-plugin-fido2-hmac
        ];
      };

      systemd.services.agenix-install-secrets = {
        after = [ "preservation.target" ];
        requires = [ "preservation.target" ];
      };

      age = {
        rekey = {
          masterIdentities = [
            ../../secrets/yubikey/yubikey_identity_usbc.pub
            ../../secrets/yubikey/yubikey_identity_usba.pub
          ];
          agePlugins = [ pkgs.age-plugin-fido2-hmac ];

          storageMode = "local";
          localStorageDir = ../../secrets/rekeyed/${config.networking.hostName};
        };
      };
    };
}
