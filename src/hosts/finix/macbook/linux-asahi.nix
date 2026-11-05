# The Asahi kernel, built from a whitelist: nothing is compiled unless it is named here.
#
# Shaped after nixos-apple-silicon's own linux-asahi package, which this replaces, and
# taking its source and version from it - so a bump of that input still moves this kernel,
# and only the configuration is ours.
#
# The point is build time at no cost in speed. nixpkgs' common config and `autoModules`
# together build most of the driver tree as modules, plus DWARF and BTF for all of it; this
# starts from `allnoconfig` and turns on what the j493 (13" M2 MacBook Pro) and this
# userland use. The list was taken from the running machine - lsmod, the drivers bound to
# its devices, and its mounts - rather than from any other machine's.
#
# Optimisation stays where the stock kernel had it: gcc at -O2, no LTO. On top of that the C
# code is tuned for the M2's cores, the same move Cerberus makes with znver5; rustc does not
# read KCFLAGS, so the Rust drivers (the GPU among them) are built as before.
#
# No hardening: allnoconfig turns it all off and nothing turns it back on. seccomp and the
# namespaces are kept, because the browser, Electron and Nix sandboxes are built on them.
_:
{ config, lib, ... }:
let
  inherit (config.hardware.asahi.pkgs) callPackage linuxPackagesFor linux-asahi;

  upstream = linux-asahi.kernel;

  linux-asahi-pkg =
    { buildLinux, ... }:
    buildLinux {
      pname = "linux-asahi";
      inherit (upstream) src version;
      modDirVersion = upstream.version;
      extraMeta.branch = lib.versions.majorMinor upstream.version;

      defconfig = "allnoconfig";
      enableCommonConfig = false;
      autoModules = false;
      # A name here which does not land in the final .config fails the build, so a typo or
      # a rename across a kernel bump is an error rather than a driver quietly missing.
      ignoreConfigErrors = false;

      extraMakeFlags = [ "KCFLAGS=-mcpu=apple-m2" ];

      kernelPatches = [
        {
          name = "j493 whitelist";
          patch = null;
          features.rust = true;
          structuredExtraConfig = with lib.kernel; {
            # -------------------------------------------------------------------------------
            # Base
            # -------------------------------------------------------------------------------
            ARCH_APPLE = yes;
            ARM64_16K_PAGES = yes;
            ARM64_VA_BITS_47 = yes; # No LPA2 on the M2, so 52 bits would fall back to this.
            NR_CPUS = freeform "8"; # 4P + 4E
            SCHED_MC = yes;
            SCHED_CLUSTER = yes;
            SCHED_AUTOGROUP = yes;
            NO_HZ_IDLE = yes;
            HIGH_RES_TIMERS = yes;
            PREEMPT_LAZY = yes;

            ARM64_MEMORY_MODEL_CONTROL = yes;
            ARM64_ACTLR_STATE = yes;
            ARM64_HW_AFDBM = yes;
            ARM64_TLB_RANGE = option yes;

            RUST = yes;
            CC_OPTIMIZE_FOR_PERFORMANCE = yes;

            MODULES = yes;
            MODULE_UNLOAD = yes;
            MODULE_COMPRESS = yes;
            MODULE_COMPRESS_ZSTD = yes;
            MODULE_COMPRESS_ALL = yes;

            # Stage 1 is off today, and hardware-configuration.nix says flipping it back is
            # all it takes to try again - so the kernel can still take an initrd.
            BLK_DEV_INITRD = yes;
            RD_ZSTD = yes;

            IKCONFIG = yes;
            IKCONFIG_PROC = yes;
            PRINTK_TIME = yes;
            MAGIC_SYSRQ = yes;

            EFI = yes;
            EFI_STUB = yes;
            EFIVAR_FS = yes;
            SYSFB_SIMPLEFB = yes;

            FW_LOADER = yes;
            FW_LOADER_COMPRESS = yes;
            FW_LOADER_COMPRESS_XZ = yes;
            FW_LOADER_COMPRESS_ZSTD = yes;

            # -------------------------------------------------------------------------------
            # Userland: finit, sandboxes, FEX
            # -------------------------------------------------------------------------------
            SECCOMP = yes;
            SECCOMP_FILTER = yes;

            SYSVIPC = yes;
            POSIX_MQUEUE = yes;
            CROSS_MEMORY_ATTACH = yes;
            INOTIFY_USER = yes;
            BINFMT_ELF = yes;
            BINFMT_SCRIPT = yes;
            BINFMT_MISC = yes; # FEX's registration
            DEVTMPFS = yes;
            DEVTMPFS_MOUNT = yes;
            TMPFS = yes;
            TMPFS_POSIX_ACL = yes;
            TMPFS_XATTR = yes;

            CGROUPS = yes;
            CGROUP_SCHED = yes;
            FAIR_GROUP_SCHED = yes;
            MEMCG = yes;
            CPUSETS = yes;
            CGROUP_PIDS = yes;
            CGROUP_FREEZER = yes;
            PSI = yes;
            BPF_SYSCALL = yes;

            NAMESPACES = yes;
            UTS_NS = yes;
            IPC_NS = yes;
            USER_NS = yes;
            PID_NS = yes;
            NET_NS = yes;

            # -------------------------------------------------------------------------------
            # Memory
            # -------------------------------------------------------------------------------
            SWAP = yes;
            ZRAM = module;
            ZRAM_BACKEND_ZSTD = yes;
            ZRAM_DEF_COMP_ZSTD = yes;
            COMPACTION = yes;
            TRANSPARENT_HUGEPAGE = yes;
            TRANSPARENT_HUGEPAGE_MADVISE = yes;
            LRU_GEN = yes;
            LRU_GEN_ENABLED = yes;

            # -------------------------------------------------------------------------------
            # Power
            # -------------------------------------------------------------------------------
            PM = yes;
            SUSPEND = yes;
            ENERGY_MODEL = yes;
            WQ_POWER_EFFICIENT_DEFAULT = yes;
            CPU_FREQ = yes;
            CPU_FREQ_GOV_SCHEDUTIL = yes;
            CPU_FREQ_DEFAULT_GOV_SCHEDUTIL = yes;
            ARM_APPLE_SOC_CPUFREQ = yes;
            CPU_IDLE = yes;
            ARM_APPLE_CPUIDLE = yes;
            ARM_ARCH_TIMER_EVTSTREAM = yes;

            # -------------------------------------------------------------------------------
            # Apple SoC
            # -------------------------------------------------------------------------------
            # DART, MAILBOX and SART are built in by finix's own config for nvme_apple.
            IOMMU_SUPPORT = yes;
            MAILBOX = yes;
            APPLE_RTKIT = yes;
            RUST_APPLE_RTKIT = yes;
            APPLE_RTKIT_HELPER = module;
            APPLE_PMGR_PWRSTATE = yes;
            APPLE_PMGR_MISC = yes;
            APPLE_PMP = yes;
            APPLE_PMP_REPORT = yes;
            APPLE_TUNABLE = module;
            APPLE_AOP = module;
            WATCHDOG = yes;
            APPLE_WATCHDOG = yes; # Might reboot the machine if not loaded soon enough.
            PERF_EVENTS = yes;
            APPLE_M1_CPU_PMU = yes; # Cannot be a module.

            PINCTRL = yes;
            PINCTRL_APPLE_GPIO = module;
            GPIOLIB = yes;
            GPIO_SHARED_PROXY = option module;
            I2C = yes;
            I2C_APPLE = module;
            SPI = yes;
            SPI_APPLE = module;
            SPMI = yes;
            SPMI_APPLE = module;
            NVMEM = yes;
            NVMEM_APPLE_SPMI = module;
            PWM = yes;
            PWM_APPLE = module;
            NEW_LEDS = yes;
            LEDS_CLASS = yes;
            LEDS_PWM = yes; # The keyboard backlight.
            COMMON_CLK_APPLE_NCO = module;
            DMADEVICES = yes;
            APPLE_ADMAC = module;
            GENERIC_PHY = yes;
            PHY_APPLE_ATC = module;
            MULTIPLEXER = yes;
            MUX_APPLE_DPXBAR = module;

            # SMC
            MFD_MACSMC = module;
            GPIO_MACSMC = module;
            HWMON = yes;
            SENSORS_MACSMC_HWMON = module;
            INPUT_MISC = yes;
            INPUT_MACSMC_INPUT = module;
            POWER_SUPPLY = yes;
            MACSMC_POWER = module;
            POWER_RESET = yes;
            POWER_RESET_MACSMC = module;
            RTC_CLASS = yes;
            RTC_DRV_MACSMC = module;

            # Ambient light
            IIO = yes;
            IIO_AOP_SENSOR_ALS = module;

            # -------------------------------------------------------------------------------
            # Storage and filesystems
            # -------------------------------------------------------------------------------
            # nvme_apple and btrfs are built in by finix, because nothing could load them.
            BTRFS_FS_POSIX_ACL = yes;
            BLK_DEV = yes; # The menu zram is in.

            # finix insists on this for nvme_apple, because on a stock kernel NVMe over
            # Fabrics' host authentication is on and selects it. allnoconfig leaves that off,
            # nothing selects NVME_AUTH, and finix's `yes` would fail as an unused option.
            # Under finix's mkForce, which is 50.
            NVME_AUTH = lib.mkOverride 40 unset;
            PCI = yes;
            PCIEPORTBUS = yes;
            PCIE_APPLE = module; # Wi-Fi sits behind it.

            VFAT_FS = yes;
            NLS = yes;
            NLS_CODEPAGE_437 = yes;
            NLS_ISO8859_1 = yes;
            NLS_UTF8 = module;
            EXFAT_FS = module;
            FUSE_FS = module;

            # -------------------------------------------------------------------------------
            # USB and USB-C
            # -------------------------------------------------------------------------------
            USB_SUPPORT = yes;
            USB = yes;
            USB_XHCI_HCD = yes;
            USB_XHCI_PLATFORM = yes;
            USB_DWC3 = yes;
            USB_DWC3_APPLE = yes;
            USB_GADGET = yes;
            USB_DWC3_DUAL_ROLE = yes;
            USB_ROLE_SWITCH = yes;
            TYPEC = module;
            TYPEC_TPS6598X = module;

            SCSI = yes;
            BLK_DEV_SD = yes;
            USB_STORAGE = module;
            USB_UAS = module;

            NETDEVICES = yes;
            USB_NET_DRIVERS = yes;
            USB_USBNET = module;
            USB_NET_CDCETHER = module;
            USB_NET_CDC_NCM = module;
            USB_RTL8152 = module;
            USB_NET_AX88179_178A = module;

            # -------------------------------------------------------------------------------
            # Input
            # -------------------------------------------------------------------------------
            INPUT = yes;
            INPUT_EVDEV = yes;
            INPUT_JOYDEV = module;
            INPUT_UINPUT = module; # tiny-dfr
            HID_SUPPORT = yes;
            HID = yes;
            HID_GENERIC = yes;
            HIDRAW = yes;
            HID_BATTERY_STRENGTH = yes;
            UHID = module; # Bluetooth LE input
            USB_HID = yes;
            HID_APPLE = module; # A module so modprobe.d can set its options.
            HID_MAGICMOUSE = module;
            HID_MULTITOUCH = module;

            # Keyboard and trackpad: on the M2 they come over DockChannel, not SPI.
            APPLE_DOCKCHANNEL = module;
            HID_DOCKCHANNEL = module;

            # The Touch Bar's digitiser.
            INPUT_TOUCHSCREEN = yes;
            TOUCHSCREEN_APPLE_Z2 = module;

            # -------------------------------------------------------------------------------
            # Display and GPU
            # -------------------------------------------------------------------------------
            DRM = yes;
            DRM_ASAHI = module;
            DRM_APPLE = module;
            DRM_SIMPLEDRM = yes;
            DRM_FBDEV_EMULATION = yes;
            FRAMEBUFFER_CONSOLE = yes;
            BACKLIGHT_CLASS_DEVICE = yes;
            VT_CONSOLE = yes;
            FONTS = yes;
            FONT_8x16 = yes;
            FONT_TER16x32 = yes;

            # The Touch Bar's display.
            DRM_ADP = module;
            DRM_MIPI_DSI = yes;
            DRM_PANEL_SUMMIT = module;

            # -------------------------------------------------------------------------------
            # Sound
            # -------------------------------------------------------------------------------
            SOUND = module;
            SND = module;
            SND_DYNAMIC_MINORS = yes;
            SND_SOC = module;
            SND_SOC_APPLE_MCA = module;
            SND_SOC_APPLE_MACAUDIO = module;
            SND_SOC_APPLE_AOP_AUDIO = module; # The microphones.
            SND_SOC_TAS2764 = module;
            SND_SOC_CS42L84 = module;
            SND_USB = yes;
            SND_USB_AUDIO = module;

            # -------------------------------------------------------------------------------
            # Camera and video decoder
            # -------------------------------------------------------------------------------
            MEDIA_SUPPORT = module;
            MEDIA_SUPPORT_FILTER = yes;
            MEDIA_SUBDRV_AUTOSELECT = no;
            MEDIA_CAMERA_SUPPORT = yes;
            MEDIA_PLATFORM_SUPPORT = yes;
            MEDIA_CONTROLLER = yes;
            MEDIA_PLATFORM_DRIVERS = yes;
            V4L_PLATFORM_DRIVERS = yes;
            V4L_MEM2MEM_DRIVERS = yes;
            VIDEO_DEV = module;
            VIDEO_APPLE_ISP = module;
            VIDEO_APPLE_AVD = module;

            # -------------------------------------------------------------------------------
            # Network
            # -------------------------------------------------------------------------------
            NET = yes;
            UNIX = yes;
            PACKET = yes;
            INET = yes;
            IP_MULTICAST = yes;
            IPV6 = yes;
            TUN = yes; # tailscale

            # tailscale's policy routing
            IP_ADVANCED_ROUTER = yes;
            IP_MULTIPLE_TABLES = yes;
            IPV6_MULTIPLE_TABLES = yes;

            NET_SCHED = yes;
            NET_SCH_FQ_CODEL = yes;
            NET_SCH_DEFAULT = yes;
            DEFAULT_FQ_CODEL = yes;

            # tailscale's firewall rules, through iptables-nft
            NETFILTER = yes;
            NETFILTER_ADVANCED = yes;
            NF_CONNTRACK = module;
            NF_NAT = module;
            NF_TABLES = module;
            NF_TABLES_INET = yes;
            NF_TABLES_IPV4 = yes;
            NF_TABLES_IPV6 = yes;
            NFT_COMPAT = module;
            NFT_CT = module;
            NFT_NAT = module;
            NFT_MASQ = module;
            NETFILTER_XTABLES = module;
            NETFILTER_XT_MARK = module;
            NETFILTER_XT_CONNMARK = module;
            NETFILTER_XT_NAT = module;
            NETFILTER_XT_TARGET_MASQUERADE = module;
            NETFILTER_XT_MATCH_ADDRTYPE = module;
            NETFILTER_XT_MATCH_CONNTRACK = module;
            IP_NF_IPTABLES = module;
            IP6_NF_IPTABLES = module;

            # Wi-Fi
            WIRELESS = yes;
            CFG80211 = module;
            RFKILL = module;
            WLAN = yes;
            WLAN_VENDOR_BROADCOM = yes;
            BRCMFMAC = module;
            BRCMFMAC_PCIE = yes;

            # Bluetooth
            BT = module;
            BT_BREDR = yes;
            BT_LE = yes;
            BT_RFCOMM = module;
            BT_BNEP = module;
            BT_HIDP = module;
            BT_HCIBCM4377 = module;
            BT_BRCMEXT = yes; # Defaults to n, and is what stops audio stuttering.

            # iwd: AF_ALG, the keyring, certificates
            KEYS = yes;
            KEY_DH_OPERATIONS = yes;
            ASYMMETRIC_KEY_TYPE = yes;
            ASYMMETRIC_PUBLIC_KEY_SUBTYPE = yes;
            X509_CERTIFICATE_PARSER = yes;
            PKCS7_MESSAGE_PARSER = yes;
            PKCS8_PRIVATE_KEY_PARSER = yes;
            CRYPTO_USER_API_HASH = module;
            CRYPTO_USER_API_SKCIPHER = module;
            CRYPTO_USER_API_AEAD = module;
            CRYPTO_AES = yes;
            CRYPTO_CBC = yes;
            CRYPTO_ECB = yes;
            CRYPTO_CMAC = yes;
            CRYPTO_HMAC = yes;
            CRYPTO_SHA1 = yes;
            CRYPTO_SHA256 = yes;
            CRYPTO_SHA512 = yes;
            CRYPTO_SHA3 = module;
            CRYPTO_MD4 = module;
            CRYPTO_MD5 = module;
            CRYPTO_DES = module;
            CRYPTO_ECDH = module;

            # Arm64 crypto extensions
            CRYPTO_AES_ARM64_CE_BLK = yes;
            CRYPTO_AES_ARM64_CE_CCM = yes;
            CRYPTO_GHASH_ARM64_CE = yes;
          };
        }
      ]
      # What asahi's module passes, and what carries finix's built-in nvme_apple and btrfs
      # and the RAID6 setting in hardware-configuration.nix. Without it they would silently
      # stop reaching this kernel.
      ++ config.boot.kernelPatches;
    };

  kernel = (callPackage linux-asahi-pkg { }).overrideAttrs (o: {
    postInstall = (o.postInstall or "") + ''
      # Only this machine's device tree: m1n1 takes whatever is here.
      find $out/dtbs -name '*.dtb' ! -name 't8112-j493.dtb' -delete
      find $out/dtbs -type d -empty -delete
    '';
  });
in
{
  # Forced, because asahi's module sets it as well.
  boot.kernelPackages = lib.mkForce (lib.recurseIntoAttrs (linuxPackagesFor kernel));
}
