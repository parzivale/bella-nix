_: {
  flake.modules.nixos.r8126 =
    { config, lib, ... }:
    let
      r8126Driver =
        config.boot.kernelPackages.callPackage
          (
            {
              stdenv,
              lib,
              fetchFromGitHub,
              kernel,
              kernelModuleMakeFlags,
            }:
            stdenv.mkDerivation (finalAttrs: {
              pname = "r8126";
              # On update, verify (via `diff -r`) that the source still matches
              # Realtek's official tarball at
              # https://www.realtek.com/Download/List?cate_id=584 (no
              # non-interactive downloads there, hence the openwrt mirror).
              version = "10.016.00";

              src = fetchFromGitHub {
                owner = "openwrt";
                repo = "rtl8126";
                tag = finalAttrs.version;
                hash = "sha256-Smf512av6B8b5dAwOLVRelBf6goLdLqSJ0bLCf+f2b8=";
              };

              hardeningDisable = [ "pic" ];

              nativeBuildInputs = kernel.moduleBuildDependencies;

              preBuild = ''
                substituteInPlace Makefile --replace-fail "BASEDIR :=" "BASEDIR ?="
                substituteInPlace Makefile --replace-fail "modules_install" "INSTALL_MOD_PATH=$out modules_install"
              '';

              # kernelModuleMakeFlags carries CC/LD/AR etc. for this kernel's
              # toolchain — Cerberus's CachyOS kernel is built with clang/lld,
              # not gcc, so building without these fails with "gcc: command
              # not found".
              makeFlags = kernelModuleMakeFlags ++ [
                "BASEDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
              ];

              buildFlags = [ "modules" ];

              meta = {
                homepage = "https://github.com/openwrt/rtl8126";
                description = "Realtek RTL8126 5GbE out-of-tree driver";
                license = lib.licenses.gpl2Only;
                platforms = lib.platforms.linux;
              };
            })
          )
          { };
    in
    {
      boot.extraModulePackages = [ r8126Driver ];
      boot.kernelModules = [ "r8126" ];
      # r8169 (in-tree) probes the RTL8126 too and wins the race if not
      # blocked, so it has to be blacklisted for r8126 to actually bind.
      boot.blacklistedKernelModules = [ "r8169" ];
    };
}
