{
  flake.modules.nixos.prismlauncher = {
    config,
    pkgs,
    lib,
    ...
  }: let
    user = config.systemConstants.username;

    # CEF runtime dependencies for MCEF mod (Wayland)
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
    ];

    # Wrap Java with CEF libraries for MCEF mod support
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
  in {
    home-manager.users.${user}.home.packages = [
      (pkgs.prismlauncher.override {
        jdks = [
          (wrapJava pkgs.jdk17)
          (wrapJava pkgs.jdk21)
        ];
      })
    ];

    preservation.preserveAt."/persistent".users.${user}.directories = [
      {
        directory = ".local/share/PrismLauncher";
        mode = "0755";
      }
    ];
  };
}
