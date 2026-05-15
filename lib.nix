{config, ...}: {
  options.reverseProxy = config.options.services.nginx.virtualHosts;
}
