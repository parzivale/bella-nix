{options, lib, config, ...}: {
  options.reverseProxy = options.services.nginx.virtualHosts;

  options.helpers = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };

  config.helpers.mkPreserve = user: attrs: {
    preserveAt."/persistent".users.${user} = attrs;
  };
}
