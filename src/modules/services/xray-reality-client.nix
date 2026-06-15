{
  flake.modules.nixos.xray-reality-client =
    {
      config,
      pkgs,
      ...
    }:
    {
      age.secrets.xray-reality-client.rekeyFile = ../../secrets/xray/reality-client.age;

      systemd.services.xray-reality-client = {
        description = "Xray VLESS+REALITY client";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "agenix-install-secrets.service"
          "xray-tproxy-routes.service"
        ];
        requires = [
          "agenix-install-secrets.service"
          "xray-tproxy-routes.service"
        ];
        script = ''
          ${pkgs.jq}/bin/jq -n \
            --arg uuid "$XRAY_UUID" \
            --arg pubkey "$XRAY_PUBLIC_KEY" \
            --arg shortid "$XRAY_SHORT_ID" \
            --arg server "$XRAY_SERVER_ADDR" \
            '{
              log: {loglevel: "warning"},
              inbounds: [
                {tag: "socks", listen: "127.0.0.1", port: 1080, protocol: "socks",
                  settings: {auth: "noauth", udp: true}},
                {tag: "http", listen: "127.0.0.1", port: 1081, protocol: "http"},
                {
                  tag: "tproxy",
                  listen: "127.0.0.1",
                  port: 12345,
                  protocol: "dokodemo-door",
                  settings: {network: "tcp,udp", followRedirect: true},
                  streamSettings: {sockopt: {tproxy: "tproxy"}},
                  sniffing: {enabled: true, destOverride: ["http","tls","quic"]}
                }
              ],
              outbounds: [
                {
                  tag: "proxy",
                  protocol: "vless",
                  settings: {
                    vnext: [{
                      address: $server,
                      port: 8443,
                      users: [{id: $uuid, flow: "xtls-rprx-vision", encryption: "none"}]
                    }]
                  },
                  streamSettings: {
                    network: "tcp",
                    security: "reality",
                    realitySettings: {
                      serverName: "www.microsoft.com",
                      fingerprint: "chrome",
                      publicKey: $pubkey,
                      shortId: $shortid
                    },
                    sockopt: {mark: 255}
                  }
                },
                {tag: "direct", protocol: "freedom", streamSettings: {sockopt: {mark: 255}}},
                {tag: "block", protocol: "blackhole"}
              ],
              routing: {
                domainStrategy: "IPIfNonMatch",
                rules: [
                  {type: "field", inboundTag: ["tproxy", "socks", "http"], outboundTag: "proxy"}
                ]
              }
            }' > /run/xray-reality-client/config.json
          exec ${pkgs.xray}/bin/xray -config /run/xray-reality-client/config.json
        '';
        serviceConfig = {
          DynamicUser = true;
          RuntimeDirectory = "xray-reality-client";
          EnvironmentFile = config.age.secrets.xray-reality-client.path;
          CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
          NoNewPrivileges = true;
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      systemd.services.xray-tproxy-routes = {
        description = "ip policy routing rules for xray tproxy";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        script = ''
          ${pkgs.iproute2}/bin/ip rule add fwmark 1 table 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip route add local 0.0.0.0/0 dev lo table 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -6 rule add fwmark 1 table 106 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -6 route add local ::/0 dev lo table 106 2>/dev/null || true
        '';
        preStop = ''
          ${pkgs.iproute2}/bin/ip rule del fwmark 1 table 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip route del local 0.0.0.0/0 dev lo table 100 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -6 rule del fwmark 1 table 106 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip -6 route del local ::/0 dev lo table 106 2>/dev/null || true
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      networking.nftables.enable = true;
      networking.nftables.tables.xray-tproxy = {
        family = "inet";
        content = ''
          chain divert {
            type filter hook prerouting priority mangle; policy accept;
            meta l4proto tcp socket transparent 1 meta mark set 0x00000001 accept
          }

          chain prerouting {
            type filter hook prerouting priority filter; policy accept;
            ip daddr { 127.0.0.0/8, 224.0.0.0/4, 255.255.255.255 } return
            ip6 daddr { ::1, fe80::/10 } return
            meta mark 0x000000ff return
            meta l4proto tcp ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } return
            ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } udp dport != 53 return
            meta l4proto tcp ip6 daddr fc00::/7 return
            ip6 daddr fc00::/7 udp dport != 53 return
            meta l4proto { tcp, udp } meta mark set 0x00000001 tproxy ip to 127.0.0.1:12345 accept
            meta l4proto { tcp, udp } meta mark set 0x00000001 tproxy ip6 to [::1]:12345 accept
          }

          chain output {
            type route hook output priority filter; policy accept;
            ip daddr { 127.0.0.0/8, 224.0.0.0/4, 255.255.255.255 } return
            ip6 daddr { ::1, fe80::/10 } return
            meta mark 0x000000ff return
            meta l4proto tcp ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } return
            ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } udp dport != 53 return
            meta l4proto tcp ip6 daddr fc00::/7 return
            ip6 daddr fc00::/7 udp dport != 53 return
            meta l4proto { tcp, udp } meta mark set 0x00000001 accept
          }
        '';
      };
    };
}
