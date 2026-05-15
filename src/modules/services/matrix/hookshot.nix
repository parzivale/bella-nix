{
  flake.modules.nixos.hookshot = {
    config,
    pkgs,
    lib,
    ...
  }: let
    domain = config.systemConstants.domain;
    matrix_domain = config.systemConstants.subDomains.matrix;
    matrix_main_port = config.systemConstants.ports.matrix.main;
    appservice_port = config.systemConstants.ports.hookshot.appservice;
    webhook_port = config.systemConstants.ports.hookshot.webhook;
    tailscale_host = "${config.networking.hostName}.${config.systemConstants.tailscale_dns}";

    registrationPath = "/var/lib/matrix-hookshot/registration.yaml";

    format = pkgs.formats.yaml {};
    configFile = format.generate "hookshot-config.yaml" {
      bridge = {
        domain = domain;
        url = "http://127.0.0.1:${toString matrix_main_port}";
        mediaUrl = "https://${matrix_domain}";
        port = appservice_port;
        bindAddress = "127.0.0.1";
      };
      passFile = config.age.secrets.hookshot-passkey.path;
      generic = {
        enabled = true;
        urlPrefix = "http://${tailscale_host}:${toString webhook_port}";
        allowJsTransformationFunctions = true;
        waitForComplete = false;
        userIdPrefix = "_webhooks_";
      };
      logging = {
        level = "warn";
        colorize = false;
      };
      connections = [
        {
          roomId = "!MSzUstXqWnQtCaRwpU:parzivale.dev";
          type = "uk.half-shot.matrix-hookshot.generic.hook";
          state = {
            stateKey = "grafana-alerts";
            config = {
              transformationFunction = ''
                const emoji = data.status === "firing" ? "🔥" : "✅";
                const status = data.status === "firing" ? "FIRING" : "RESOLVED";
                const alerts = data.alerts.map(function(a) {
                  const name = a.labels.alertname || "Unknown";
                  const summary = a.annotations.summary || a.annotations.description || "";
                  return summary ? ("• " + name + ": " + summary) : ("• " + name);
                }).join("\n");
                return {
                  plain: emoji + " " + status + ": " + data.title + "\n" + alerts,
                  msgtype: "m.text"
                };
              '';
            };
          };
        }
      ];
      listeners = [
        {
          port = webhook_port;
          bindAddress = "0.0.0.0";
          resources = ["webhooks"];
        }
      ];
    };

    generateRegistration = pkgs.writeShellScript "hookshot-gen-registration" ''
      cat > ${registrationPath} << EOF
      id: hookshot
      url: "http://127.0.0.1:${toString appservice_port}"
      as_token: "$AS_TOKEN"
      hs_token: "$HS_TOKEN"
      rate_limited: false
      sender_localpart: hookshot
      namespaces:
        users:
          - exclusive: true
            regex: "@_webhooks_.*:${domain}"
        rooms: []
        aliases: []
      EOF
      chmod 640 ${registrationPath}
    '';
  in {
    age.secrets.hookshot-passkey = {
      rekeyFile = ../../../secrets/hookshot/passkey.age;
      owner = "matrix-hookshot";
    };
    age.secrets.hookshot-tokens = {
      rekeyFile = ../../../secrets/hookshot/tokens.age;
      owner = "matrix-hookshot";
    };

    services.matrix-synapse.settings.app_service_config_files = [registrationPath];

    systemd.services.matrix-hookshot-gen-registration = {
      description = "Generate Matrix Hookshot registration file";
      before = ["matrix-synapse.service" "matrix-hookshot.service"];
      wantedBy = ["matrix-synapse.service"];
      after = ["agenix-install-secrets.service"];
      requires = ["agenix-install-secrets.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "matrix-hookshot";
        Group = "matrix-hookshot";
        EnvironmentFile = config.age.secrets.hookshot-tokens.path;
        ExecStart = generateRegistration;
        StateDirectory = "matrix-hookshot";
      };
    };

    users.users.matrix-synapse.extraGroups = ["matrix-hookshot"];

    systemd.services.matrix-hookshot = {
      description = "Matrix Hookshot";
      after = ["network.target" "matrix-synapse.service" "matrix-hookshot-gen-registration.service"];
      requires = ["matrix-synapse.service" "matrix-hookshot-gen-registration.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "simple";
        User = "matrix-hookshot";
        Group = "matrix-hookshot";
        StateDirectory = "matrix-hookshot";
        ExecStart = "${lib.getExe pkgs.matrix-hookshot} ${configFile} ${registrationPath}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    users.users.matrix-hookshot = {
      isSystemUser = true;
      group = "matrix-hookshot";
    };
    users.groups.matrix-hookshot = {};

    preservation.preserveAt."/persistent".directories = [
      {directory = "/var/lib/matrix-hookshot";}
    ];
  };
}
