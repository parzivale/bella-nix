{ lib, ... }:
let
  # The one path sudoers has to name. deploy-rs prefixes its `sudo` setting
  # verbatim to every privileged command it sends, so pointing that setting
  # here is all it takes to turn four store-path-globbed rules into one rule
  # about a fixed path. /run/current-system/sw/bin survives a generation
  # change; a store path does not.
  wrapper = "/run/current-system/sw/bin/deploy-activate";

  # Trailing newline and all, as `readFile` gives it. It is passed to nix as a
  # single `--option` value, where the newline would be part of the key.
  deployKey = lib.removeSuffix "\n" (
    builtins.readFile ../../secrets/master/nix-deploy/deploy-key.pub
  );

  # deploy-rs sends exactly four privileged commands, built in src/deploy.rs by
  # build_activate_command, build_wait_command, build_revoke_command and
  # confirm_profile. Each is `<sudo setting> <user> <command>`, so this script
  # sees `root` followed by one of:
  #
  #   <closure>/activate-rs [globals] activate <closure> <profile> --temp-path P [--confirm-timeout N] [flags]
  #   <closure>/activate-rs [globals] wait <closure> --temp-path P [--activation-timeout N]
  #   <closure>/activate-rs [globals] revoke <profile>
  #   rm <temp-path>/deploy-rs-canary-<closure hash>
  #
  # It parses those and rebuilds them, rather than forwarding what it was
  # handed. Forwarding would make it a root shell: it runs under a sudoers rule
  # with a wildcard for arguments, so the argument checking *is* the rule. The
  # arguments that matter are the ones activate-rs turns into paths it writes
  # as root - --log-dir, --profile-path, --profile-user/--profile-name - and
  # the `closure` positional, which deploy-rs always sets to the closure the
  # binary came from but which nothing forces to match.
  #
  # Upgrading deploy-rs means re-reading those four builders: a new argument
  # arrives here as a refusal, not as a silent pass-through.
  script =
    pkgs: nix:
    pkgs.writeShellApplication {
      name = "deploy-activate";
      runtimeInputs = [
        pkgs.coreutils
        nix
      ];
      text = ''
        die() {
          printf 'deploy-activate: %s\n' "$*" >&2
          exit 1
        }

        # The gate. A closure built on this machine is `ultimate` in the nix
        # database, and an ultimately-trusted path passes `nix store verify`
        # with no signature at all - unless --sigs-needed is given, which stops
        # the ultimate bit short-circuiting the check. The key is named here
        # rather than left to nix.conf because this check runs client-side, so
        # trusted-public-keys from the environment would otherwise count.
        verify() {
          nix --extra-experimental-features nix-command \
            store verify --sigs-needed 1 \
            --option trusted-public-keys '${deployKey}' \
            "$1" > /dev/null 2>&1 ||
            die "closure is not signed by the deploy key: $1"
        }

        [ "$#" -ge 2 ] || die "expected a user and a command"
        [ "$1" = root ] || die "refusing to act as: $1"
        shift

        # Removing the canary is how deploy-rs confirms a deployment. `rm` on a
        # symlink removes the symlink, so a canary pointed at something else is
        # not a way to delete it.
        if [ "$1" = rm ]; then
          [ "$#" -eq 2 ] || die "rm takes exactly one argument"
          [[ "$2" =~ ^/tmp/deploy-rs-canary-[a-z0-9]{32}$ ]] || die "not a canary path: $2"
          exec rm -- "$2"
        fi

        activate=$1
        shift
        [[ "$activate" =~ ^/nix/store/[a-z0-9]{32}-[^/]+/activate-rs$ ]] ||
          die "not an activate-rs path: $activate"
        closure=''${activate%/activate-rs}

        # Global options, dropped rather than forwarded. --debug-logs only
        # changes verbosity, but --log-dir names a directory root writes to.
        while [ "$#" -gt 0 ]; do
          case "$1" in
          --debug-logs) shift ;;
          --log-dir) shift 2 ;;
          *) break ;;
          esac
        done

        [ "$#" -ge 1 ] || die "no subcommand"
        subcommand=$1
        shift

        case "$subcommand" in
        activate | wait)
          # The binary is from a signed closure; the closure it is told to
          # activate is a separate argument. Requiring them to be the same is
          # what stops a signed activate-rs being aimed at an unsigned closure.
          [ "$#" -ge 1 ] || die "no closure"
          [ "$1" = "$closure" ] || die "closure does not match the binary: $1"
          shift
          ;;
        revoke) ;;
        *) die "unknown subcommand: $subcommand" ;;
        esac

        profile_user=""
        profile_name=""
        profile_path=""
        extra=()

        while [ "$#" -gt 0 ]; do
          case "$1" in
          --profile-user)
            profile_user=$2
            shift 2
            ;;
          --profile-name)
            profile_name=$2
            shift 2
            ;;
          --profile-path)
            profile_path=$2
            shift 2
            ;;
          --temp-path)
            # Forced to /tmp below. Both sides have to agree on it: the canary
            # this creates is the one the `rm` above is allowed to remove.
            [ "$2" = /tmp ] || die "temp path is not /tmp: $2"
            shift 2
            ;;
          --confirm-timeout | --activation-timeout)
            [[ "$2" =~ ^[0-9]+$ ]] || die "non-numeric timeout: $2"
            extra+=("$1" "$2")
            shift 2
            ;;
          --magic-rollback | --auto-rollback | --boot | --test | --dry-activate)
            extra+=("$1")
            shift
            ;;
          *) die "unexpected argument: $1" ;;
          esac
        done

        # activate-rs builds a path out of whichever of these it is given:
        # --profile-path verbatim, or /nix/var/nix/profiles[/per-user/<user>]/<name>.
        # Either way it then points that path at the closure as root, so both
        # forms are held inside /nix/var/nix/profiles.
        profile=()
        resolve_profile() {
          if [ -n "$profile_path" ]; then
            [ -z "$profile_user$profile_name" ] || die "two profile forms given"
            [[ "$profile_path" =~ ^/nix/var/nix/profiles/[A-Za-z0-9_.-]+$ ]] ||
              die "profile path outside /nix/var/nix/profiles: $profile_path"
            profile=(--profile-path "$profile_path")
          else
            [ "$profile_user" = root ] || die "profile user is not root: $profile_user"
            [[ "$profile_name" =~ ^[A-Za-z0-9_-]+$ ]] || die "bad profile name: $profile_name"
            profile=(--profile-user root --profile-name "$profile_name")
          fi
        }

        verify "$closure"

        case "$subcommand" in
        activate)
          resolve_profile
          exec "$activate" activate "$closure" "''${profile[@]}" \
            --temp-path /tmp "''${extra[@]}"
          ;;
        wait)
          exec "$activate" wait "$closure" --temp-path /tmp "''${extra[@]}"
          ;;
        revoke)
          resolve_profile
          exec "$activate" revoke "''${profile[@]}"
          ;;
        esac
      '';
    };
in
{
  flake.modules.nixos.deploy-user =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [ (script pkgs config.nix.package) ];

      security.sudo.extraRules = [
        {
          users = [ config.constants.username ];

          # Otherwise `ALL:ALL`, which is what NixOS defaults to and which lets
          # this be run as any user - wider than deploy-rs ever asks for, since
          # it only ever sends `root`. The finix rule says the same thing
          # through `providers.privileges`, which defaults to root already.
          runAs = "root";

          commands = [
            {
              # A wildcard for the arguments is safe here only because the
              # wrapper refuses anything it does not recognise. sudoers matches
              # arguments as one concatenated string, so a `*` crosses word
              # boundaries - which is exactly why the rules this replaces had
              # to be written as anchored regexes.
              command = "${wrapper} *";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

  flake.modules.finix.deploy-user =
    {
      config,
      pkgs,
      modules,
      ...
    }:
    {
      # `services.nix-daemon` for the same reason `signed-nix` imports it: on
      # finix the option only exists where the module is pulled in, and the
      # wrapper wants the nix the daemon is actually running.
      imports = [ modules.nix-daemon ];

      environment.systemPackages = [ (script pkgs config.services.nix-daemon.package) ];

      # `providers.privileges` rather than `security.sudo`: finix has a
      # contract for "let this user run that as root", implemented by either
      # sudo or doas, and a host picks which. `command` and `args` pass through
      # verbatim, so the `*` means what it means to sudoers and matches
      # literally under doas - a host on the doas backend finds out by the rule
      # not matching.
      providers.privileges.rules = [
        {
          command = wrapper;
          args = [ "*" ];
          users = [ config.constants.username ];
          requirePassword = false;
        }
      ];
    };
}
