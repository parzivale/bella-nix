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
    java-with-cef = pkgs.symlinkJoin {
      name = "java-with-cef";
      paths = [pkgs.jdk21];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/java \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath cefLibs}"
      '';
    };
  in {
    home-manager.users.${user}.home.packages = [
      (pkgs.prismlauncher.override {
        jdks = [java-with-cef];
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
