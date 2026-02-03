{lib, ...}: {
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = lib.mkDefault true;
    publish = {
      enable = lib.mkDefault true;
      domain = lib.mkDefault true;
      addresses = lib.mkDefault true;
      userServices = lib.mkDefault true;
    };
  };
}
