{
  vars,
  pkgs,
  ...
}: let
  user = vars.username;
in {
  home-manager.users.${user} = {
    xdg.userDirs.enable = false;
    home.stateVersion = "25.11";
  };

  services.getty.autologinUser = user;

  environment.systemPackages = [pkgs.nixos-facter pkgs.age pkgs.age-plugin-fido2-hmac];
  programs.ssh.startAgent = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.domain = true;
  services.avahi.publish.addresses = true;
  services.avahi.publish.userServices = true;
  networking.nameservers = ["1.1.1.1"];
  system.stateVersion = "25.11";
}
