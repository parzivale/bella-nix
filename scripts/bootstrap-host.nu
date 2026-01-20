#!/usr/bin/env -S nix shell nixpkgs#nushell nixpkgs#age nixpkgs#openssl nixpkgs#coreutils nixpkgs#avahi nixpkgs#fzf --command nu
const BOOTSTRAP_HOSTNAME = "bootstrap.local"
let ARTIFACTS = (mktemp -d -t bootstrap-XXXXXX | str trim)
let PROJECT_ROOT = (pwd)
let HOSTS_DIR = $"($PROJECT_ROOT)/src/hosts"
let TEMPLATE_DIR = $"($PROJECT_ROOT)/template/host"
let YUBIKEY_PUB = $"($PROJECT_ROOT)/src/common/secrets/yubikey_identity.pub"
let VARS_FILE = $"($PROJECT_ROOT)/vars.nix"
let SSH_USER = (nix eval --raw -f $VARS_FILE username)
let CHALLENGE_1 = $"($ARTIFACTS)/c1.age"
def prompt_key_local [] {
    print ""
    print "=================================================================="
    print " 🔌  ACTION REQUIRED: YUBIKEY -> LOCAL "
    print "=================================================================="
    print "Please plug your YubiKey into THIS machine (Local)."
    print "Needed for: SSH Authentication / File Transfer"
    print "------------------------------------------------------------------"
    input "Press [Enter] when the key is connected locally..."
}
def prompt_key_remote [host: string] {
    print ""
    print "=================================================================="
    print $" 🔌  ACTION REQUIRED: YUBIKEY -> REMOTE ({host})"
    print "=================================================================="
    print "Please plug your YubiKey into the TARGET machine."
    print "Needed for: Identity Attestation (Decryption)"
    print "------------------------------------------------------------------"
    input "Press [Enter] when the key is connected remotely..."
}
def ssh_with_opts [command: string, user: string, host: string] { ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=($ARTIFACTS)/ssh-%r@%h:%p" -o ControlPersist=10m $"($user)@($host)" $command }
def scp_with_opts_up [
    infile: path
    outfile: path
    user: string
    host: string
] { scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=($ARTIFACTS)/ssh-%r@%h:%p" -o ControlPersist=10m $infile $"($user)@($host):($outfile)" }
def scp_with_opts_down [
    infile: path
    outfile: path
    user: string
    host: string
] { scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ControlMaster=auto -o $"ControlPath=($ARTIFACTS)/ssh-%r@%h:%p" -o ControlPersist=10m $"($user)@($host):($infile)" $outfile }
def init [TARGET_DIR: string] {
    prompt_key_local
    print "==> Adding key to agent\n"
    ssh-add -K
    print $"==> Checking for ($BOOTSTRAP_HOSTNAME)...\n"
    try {
        ping -c 1 -W 2 -q $BOOTSTRAP_HOSTNAME
        print "\n==> Found host\n"
    } catch {
        print "==> Error: Host unreachable\n"
        exit 1
    }
    if ($TARGET_DIR | path exists) {
        print $"==> Error: Host directory ($TARGET_DIR) already exists."
        exit 1
    }
    print $"==> Scaffolding ($TARGET_DIR)...\n"
    mkdir $HOSTS_DIR
    cp -r $TEMPLATE_DIR $TARGET_DIR
    let addr = avahi-resolve-host-name $BOOTSTRAP_HOSTNAME | str substring 15.. | str trim
    print "==> Initial ssh connection\n"
    ssh_with_opts "echo '==> Connected to host\n'" $SSH_USER $addr
    $addr
}
def verify_identity [addr: string, TARGET_DIR: string] {
    print "==> Generating Challenge...\n"
    openssl rand -hex 32 | str trim | save $"($ARTIFACTS)/c1.txt"
    age -r (
        open $YUBIKEY_PUB | lines | first | split words | last
    ) -o $CHALLENGE_1 $"($ARTIFACTS)/c1.txt"
    print $"==> Uploading challenge to ($BOOTSTRAP_HOSTNAME)...\n"
    scp_with_opts_up $CHALLENGE_1 "/tmp/verify.age" $SSH_USER $addr
    scp_with_opts_up $YUBIKEY_PUB "/tmp/yubikey_identity.pub" $SSH_USER $addr
    prompt_key_remote $BOOTSTRAP_HOSTNAME
    print "==> Verifying identity on remote...\n"
    ssh_with_opts $'set -euo pipefail; echo "Decrypting..."; age -d -i /tmp/yubikey_identity.pub -o /tmp/verified.txt /tmp/verify.age' $SSH_USER $addr
    prompt_key_local
    print "==> Retrieving proof...\n"
    scp_with_opts_down /tmp/verified.txt $"($ARTIFACTS)/c1_returned.txt" $SSH_USER $addr
    let challenge_match = (open $"($ARTIFACTS)/c1.txt" | str trim) == (open $"($ARTIFACTS)/c1_returned.txt" | str trim)
    if not $challenge_match {
        print "!!!!!! SECURITY ALERT !!!!!!"
        print "Attestation Failed! Remote content does not match local challenge."
        exit 1
    }
    print "==> Identity confirmed."
}
def main [TARGET_HOSTNAME: string] {
    let TARGET_DIR = $"($HOSTS_DIR)/($TARGET_HOSTNAME)"
    let bootstrap_ip = init $TARGET_DIR
    verify_identity $bootstrap_ip $TARGET_DIR
    ssh_with_opts "echo 'Scanning Hardware'; sudo nixos-facter > /tmp/facter.json" $SSH_USER $bootstrap_ip
    let facter = $"($TARGET_DIR)/facter.json"
    scp_with_opts_down /tmp/facter.json $facter $SSH_USER $bootstrap_ip
    let disks = open $facter | get hardware.disk | where { |item|
        ($item.resources? | default []) | any { |res|
            $res.type == "size" and ($res.value_1? | default 0) * ($res.value_2? | default 0) > 32_000_000_000
        }
    }

    let selected_disk = $disks | get model | str join "\n" | fzf

}
