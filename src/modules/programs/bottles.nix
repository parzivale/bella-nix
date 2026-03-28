{
  flake.modules.nixos.bottles = {
    config,
    pkgs,
    ...
  }: let
    user = config.systemConstants.username;
  in {
    # Allow Bottles' downloaded x86_64 wine runners to execute on ARM via FEX
    boot.binfmt.registrations.fex-x86_64 = {
      interpreter = "${pkgs.fex-headless}/bin/FEXInterpreter";
      # x86_64 ELF executable magic
      magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00'';
      mask = ''\xff\xff\xff\xff\xff\xfe\xfe\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
    };

    home-manager.users.${user} = {
      home.packages = [pkgs.bottles pkgs.fex-headless];
      xdg.desktopEntries."com.usebottles.bottles" = {
        name = "Bottles";
        icon = "com.usebottles.bottles";
        exec = "/etc/profiles/per-user/${user}/bin/bottles";
        terminal = false;
        categories = ["Utility" "Game" "Graphics" "Emulator"];
        mimeType = [
          "x-scheme-handler/bottles"
          "application/x-ms-dos-executable"
          "application/x-msi"
          "application/x-ms-shortcut"
          "application/x-wine-extension-msp"
        ];
        startupNotify = true;
      };
    };
    preservation.preserveAt."/persistent".users.${user} = {
      directories = [
        {
          directory = ".local/share/bottles";
        }
      ];
    };
  };
}
