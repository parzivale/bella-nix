{
  username = "bella";
  uid = 1000;
  email = "zeus@theolivers.org";
  tailscale_dns = "tail1c0747.ts.net";
  bg_img = builtins.fetchurl {
    url = "https://w.wallhaven.cc/full/8g/wallhaven-8ge2x1.png";
    sha256 = "sha256-tQkP1g9KkOmc6IZgWhok8xuzjd0hu+IKOCp+SM0arQk=";
  };
}
