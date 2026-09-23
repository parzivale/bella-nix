{ inputs, ... }:
let
  # The keyring itself is per-user state, and both classes implement
  # `state.preserve`, so that part is the same either way.
  keyrings =
    { config, ... }:
    let
      user = config.systemConstants.username;
    in
    {
      state.preserve.users.${user} = {
        directories = [
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
        ];
      };
    };
in
{
  flake.modules.nixos.keyring = {
    imports = [ keyrings ];

    services.gnome.gnome-keyring.enable = true;

    security.pam.services = {
      login.enableGnomeKeyring = true;
      greetd.enableGnomeKeyring = true;
    };
  };

  flake.modules.finix.keyring =
    { modules, ... }:
    {
      imports = [
        keyrings
        modules.gnome-keyring
      ];

      # `programs` rather than `services.gnome`, and the module does rather
      # more: the daemon needs `cap_ipc_lock` to keep secrets out of swap, so
      # it sets up a wrapper, registers the dbus services and the portal.
      programs.gnome-keyring.enable = true;

      # Nothing corresponds to `enableGnomeKeyring` on the pam services. On
      # NixOS that inserts pam_gnome_keyring into login and greetd, which is
      # what unlocks the keyring with the login password; finix's pam module
      # has no such switch, so the keyring will want unlocking by hand until
      # that exists upstream.
    };
}
