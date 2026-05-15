{
  flake.modules.nixos.grocy = {
    config,
    pkgs,
    ...
  }: let
    grocy_domain = config.systemConstants.subDomains.grocy;
    dataDir = "/var/lib/grocy";
    pkg = pkgs.grocy;
  in {
    environment.etc."grocy/config.php".text = ''
      <?php
      Setting('CULTURE', 'en');
      Setting('CURRENCY', 'SEK');
      Setting('CALENDAR_FIRST_DAY_OF_WEEK', ''');
      Setting('CALENDAR_SHOW_WEEK_OF_YEAR', true);
      Setting('ENTRY_PAGE', 'stock');
    '';

    users.users.grocy = {
      isSystemUser = true;
      createHome = true;
      home = dataDir;
      group = "nginx";
    };

    systemd.tmpfiles.rules = map (d: "d '${dataDir}/${d}' - grocy nginx - -") [
      "viewcache"
      "plugins"
      "settingoverrides"
      "storage"
    ];

    services.phpfpm.pools.grocy = {
      user = "grocy";
      group = "nginx";
      inherit (pkg.passthru) phpPackage;
      settings = {
        "pm" = "dynamic";
        "php_admin_value[error_log]" = "stderr";
        "php_admin_flag[log_errors]" = true;
        "listen.owner" = config.services.nginx.user;
        "catch_workers_output" = true;
        "pm.max_children" = "32";
        "pm.start_servers" = "2";
        "pm.min_spare_servers" = "2";
        "pm.max_spare_servers" = "4";
        "pm.max_requests" = "500";
      };
      phpEnv = {
        GROCY_CONFIG_FILE = "/etc/grocy/config.php";
        GROCY_DB_FILE = "${dataDir}/grocy.db";
        GROCY_STORAGE_DIR = "${dataDir}/storage";
        GROCY_PLUGIN_DIR = "${dataDir}/plugins";
        GROCY_CACHE_DIR = "${dataDir}/viewcache";
        GROCY_BASE_URL = "https://${grocy_domain}";
      };
    };

    systemd.services.grocy-setup = {
      wantedBy = ["multi-user.target"];
      before = ["phpfpm-grocy.service"];
      unitConfig.RequiresMountsFor = [dataDir];
      script = "rm -rf ${dataDir}/viewcache/*";
    };

    services.nginx.enable = true;

    services.nginx.virtualHosts.${grocy_domain} = {
      forceSSL = true;
      enableACME = true;
      quic = true;
      root = "${pkg}/public";
      locations."/".extraConfig = "rewrite ^ /index.php;";
      locations."~ \\.php$".extraConfig = ''
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${config.services.phpfpm.pools.grocy.socket};
        fastcgi_param HTTPS on;
        include ${config.services.nginx.package}/conf/fastcgi.conf;
        include ${config.services.nginx.package}/conf/fastcgi_params;
      '';
      locations."~ \\.(js|css|ttf|woff2?|png|jpe?g|svg)$".extraConfig = ''
        add_header Cache-Control "public, max-age=15778463";
        add_header X-Content-Type-Options nosniff;
        add_header X-Robots-Tag none;
        add_header X-Download-Options noopen;
        add_header X-Permitted-Cross-Domain-Policies none;
        add_header Referrer-Policy no-referrer;
        access_log off;
      '';
      extraConfig = "try_files $uri /index.php;";
    };

    preservation.preserveAt."/persistent".directories = [
      {
        directory = dataDir;
        user = "grocy";
        group = "nginx";
      }
    ];
  };
}
