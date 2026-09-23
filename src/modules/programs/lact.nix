{
  flake.modules.nixos.lact = {
    services.lact.enable = true;

    state.preserve.directories = [ "/etc/lact" ];
  };
}
