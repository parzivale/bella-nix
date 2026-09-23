_: {
  # `reverseProxy.<host>` is an alias for `services.nginx.virtualHosts.<host>`,
  # so a service can declare its own vhost without naming nginx. It lived in
  # lib.nix, which every host imported whether or not it ran a web server;
  # nginx.nix imports it now, so it arrives with the thing it aliases.
  flake.modules.nixos.reverse-proxy =
    { options, ... }:
    {
      options.reverseProxy = options.services.nginx.virtualHosts;
    };
}
