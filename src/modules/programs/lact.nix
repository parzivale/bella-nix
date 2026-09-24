_: {
  flake.modules.nixos.lact = {
    services.lact.enable = true;

    state.preserve.directories = [ "/etc/lact" ];
  };

  # finix had no lact; the module is there now, so what is left here is the same
  # two lines. /etc/lact is preserved rather than `settings` being set, so the
  # daemon keeps ownership of the file and the GUI can still write it.
  flake.modules.finix.lact =
    { modules, ... }:
    {
      imports = [ modules.lact ];

      services.lact.enable = true;

      state.preserve.directories = [ "/etc/lact" ];
    };
}
