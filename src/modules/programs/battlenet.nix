{self, ...}: {
  flake.modules.nixos.battlenet = {
    config,
    pkgs,
    lib,
    ...
  }: let
    user = config.systemConstants.username;
    wine = "${pkgs.wineWow64Packages.stagingFull}/bin/wine";

    installer = pkgs.fetchurl {
      name = "Battle.net-Setup.exe";
      url = "https://www.battle.net/download/getInstallerForGame?os=win&locale=enUS&version=LIVE&gameProgram=BATTLENET_APP";
      hash = lib.fakeHash;
    };

    battlenet-exe = ".wine/drive_c/Program Files (x86)/Battle.net/Battle.net.exe";

    battlenet-launcher = pkgs.writeShellScriptBin "battlenet" ''
      if [ ! -f "$HOME/${battlenet-exe}" ]; then
        ${wine} ${installer}
      fi
      ${wine} "$HOME/${battlenet-exe}"
    '';
  in {
    imports = [self.modules.nixos.wine];

    home-manager.users.${user} = {
      home.packages = [battlenet-launcher];
      xdg.desktopEntries.battlenet = {
        name = "Battle.net";
        exec = "battlenet";
        terminal = false;
        categories = ["Game"];
        comment = "Blizzard Battle.net launcher";
      };
    };
  };
}
