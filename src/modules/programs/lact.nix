{
  flake.modules.nixos.lact = {
    services.lact.enable = true;

    preservation.preserveAt."/persistent".directories = [ "/etc/lact" ];
  };
}
