{
  flake.modules.nixos.xray-xhttp =
    {
      config,
      pkgs,
      ...
    }:
    let
      port = config.systemConstants.ports.xray.xhttp;
      vpn_domain = config.systemConstants.subDomains.vpn;
    in
    {
      age.secrets.xray-xhttp-server.rekeyFile = ../../secrets/xray/xhttp-server.age;

      systemd.services.xray-xhttp = {
        description = "Xray VLESS+xhttp server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "agenix-install-secrets.service"
        ];
        requires = [ "agenix-install-secrets.service" ];
        script = ''
          ${pkgs.jq}/bin/jq -n \
            --arg uuid "$XRAY_UUID" \
            --argjson port ${toString port} \
            '{
              log: {loglevel: "warning"},
              inbounds: [{
                tag: "vless-xhttp-in",
                listen: "127.0.0.1",
                port: $port,
                protocol: "vless",
                settings: {
                  clients: [{id: $uuid, flow: ""}],
                  decryption: "none"
                },
                streamSettings: {
                  network: "xhttp",
                  security: "none",
                  xhttpSettings: {path: "/xray", mode: "auto"}
                },
                sniffing: {enabled: true, destOverride: ["http","tls","quic"]}
              }],
              outbounds: [
                {tag: "direct", protocol: "freedom"},
                {tag: "block", protocol: "blackhole"}
              ]
            }' > /run/xray-xhttp/config.json
          exec ${pkgs.xray}/bin/xray -config /run/xray-xhttp/config.json
        '';
        serviceConfig = {
          DynamicUser = true;
          RuntimeDirectory = "xray-xhttp";
          EnvironmentFile = config.age.secrets.xray-xhttp-server.path;
          NoNewPrivileges = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      reverseProxy.${vpn_domain} = {
        forceSSL = true;
        enableACME = true;
        quic = true;
        locations."/xray" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_buffering off;
            proxy_request_buffering off;
            proxy_read_timeout 86400s;
          '';
        };
      };
    };
}
