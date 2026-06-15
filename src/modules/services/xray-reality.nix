{
  flake.modules.nixos.xray-reality =
    {
      config,
      pkgs,
      ...
    }:
    let
      port = config.systemConstants.ports.xray.reality;
    in
    {
      age.secrets.xray-reality-server.rekeyFile = ../../secrets/xray/reality-server.age;

      systemd.services.xray-reality = {
        description = "Xray VLESS+REALITY server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "agenix-install-secrets.service"
        ];
        requires = [ "agenix-install-secrets.service" ];
        script = ''
          ${pkgs.jq}/bin/jq -n \
            --arg uuid "$XRAY_UUID" \
            --arg privkey "$XRAY_PRIVATE_KEY" \
            --arg shortid "$XRAY_SHORT_ID" \
            --argjson port ${toString port} \
            '{
              log: {loglevel: "warning"},
              inbounds: [{
                tag: "vless-reality-in",
                port: $port,
                protocol: "vless",
                settings: {
                  clients: [{id: $uuid, flow: "xtls-rprx-vision"}],
                  decryption: "none"
                },
                streamSettings: {
                  network: "tcp",
                  security: "reality",
                  realitySettings: {
                    show: false,
                    dest: "www.microsoft.com:443",
                    serverNames: ["www.microsoft.com"],
                    privateKey: $privkey,
                    shortIds: [$shortid]
                  }
                },
                sniffing: {enabled: true, destOverride: ["http","tls","quic"]}
              }],
              outbounds: [
                {tag: "direct", protocol: "freedom"},
                {tag: "block", protocol: "blackhole"}
              ]
            }' > /run/xray-reality/config.json
          exec ${pkgs.xray}/bin/xray -config /run/xray-reality/config.json
        '';
        serviceConfig = {
          DynamicUser = true;
          RuntimeDirectory = "xray-reality";
          EnvironmentFile = config.age.secrets.xray-reality-server.path;
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          NoNewPrivileges = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      networking.firewall = {
        allowedTCPPorts = [ port ];
        allowedUDPPorts = [ port ];
      };
    };
}
