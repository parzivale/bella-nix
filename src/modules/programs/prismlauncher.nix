{inputs, ...}: {
  flake.modules.homeManager.prismlauncher = {pkgs, lib, ...}: let
    cefLibs = with pkgs; [
      libgbm
      glib
      nss
      nspr
      libdrm
      expat
      libxkbcommon
      mesa
      alsa-lib
      dbus
      at-spi2-core
      cups
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxshmfence
      atk
      at-spi2-atk
      gtk3
      pango
      cairo
    ];

    wrapJava = jdk:
      pkgs.symlinkJoin {
        name = "${jdk.pname}-with-cef";
        paths = [jdk];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/java \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath cefLibs}"
        '';
      };

    prismlauncherDgpu = pkgs.symlinkJoin {
      name = "prismlauncher-dgpu";
      paths = [
        (pkgs.prismlauncher.override {
          jdks = [
            (wrapJava pkgs.jdk17)
            (wrapJava pkgs.jdk21)
            (wrapJava pkgs.jdk25)
          ];
        })
      ];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/prismlauncher \
          --set DRI_PRIME 1
      '';
    };
  in {
    home.packages = [prismlauncherDgpu];
  };

  flake.modules.nixos.prismlauncher = {
    config,
    pkgs,
    lib,
    ...
  }: let
    user = config.systemConstants.username;

    cefLibs = with pkgs; [
      libgbm
      glib
      nss
      nspr
      libdrm
      expat
      libxkbcommon
      mesa
      alsa-lib
      dbus
      at-spi2-core
      cups
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxshmfence
      atk
      at-spi2-atk
      gtk3
      pango
      cairo
    ];
  in {
    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.prismlauncher];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {
        directory = ".local/share/PrismLauncher";
        mode = "0755";
      }
    ];

    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = cefLibs;
  };
}
