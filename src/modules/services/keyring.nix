{
  flake.modules.nixos.keyring =
    {
      config,
      ...
    }:
    let
      user = config.systemConstants.username;
    in
    {
      services.gnome.gnome-keyring.enable = true;

      security.pam.services = {
        login.enableGnomeKeyring = true;
        greetd.enableGnomeKeyring = true;
      };

      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
        ];
      };
    };
}
