{inputs, ...}: {
  flake.modules.homeManager.battlenet = {pkgs, lib, ...}: let
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
    home.packages = [battlenet-launcher];
    xdg.desktopEntries.battlenet = {
      name = "Battle.net";
      exec = "battlenet";
      terminal = false;
      categories = ["Game"];
      comment = "Blizzard Battle.net launcher";
    };
  };

  flake.modules.nixos.battlenet = {config, ...}: let
    user = config.systemConstants.username;
  in {
    imports = [inputs.self.modules.nixos.wine];

    home-manager.users.${user}.imports = [inputs.self.modules.homeManager.battlenet];
  };
}
