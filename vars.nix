rec {
  username = "bella";
  uid = 1000;
  email = "zeus@theolivers.org";
  tailscale_dns = "tail1c0747.ts.net";
  bg_img = builtins.fetchurl {
    url = "https://w.wallhaven.cc/full/8g/wallhaven-8ge2x1.png";
    sha256 = "sha256-tQkP1g9KkOmc6IZgWhok8xuzjd0hu+IKOCp+SM0arQk=";
  };
  domain = "parzivale.dev";
  monitoringHost = "embla";

  subDomains = rec {
    pocket-id = "id.${domain}";
    matrix = "matrix.${domain}";
    mas = "auth.${matrix}";
    grafana = "grafana.${domain}";
    grocy = "grocy.${domain}";
  };

  ports = {
    matrix = {
      mas = {
        web = 8009;
        internal = 8010;
      };
      main = 8008;
    };
    grafana = 3000;
    loki = 3100;
    prometheus = {
      main = 9090;
      exporter = 9100;
    };
    tempo = {
      main = 3200;
      grpc = 4317;
      http = 4318;
    };
    pocket-id = 1411;
  };
}
