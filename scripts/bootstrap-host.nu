#!/usr/bin/env -S nix shell nixpkgs#nushell nixpkgs#age nixpkgs#openssl nixpkgs#coreutils nixpkgs#jq --command nu

const BOOTSTRAP_HOSTNAME = "bootstrap.local"
let ARTIFACTS = (mktemp -d -t bootstrap-XXXXXX | str trim)
let PROJECT_ROOT = (pwd)
let HOSTS_DIR = $"($PROJECT_ROOT)/src/hosts"
let TEMPLATE_DIR = $"($PROJECT_ROOT)/template/host"
let YUBIKEY_PUB = $"($PROJECT_ROOT)/src/common/secrets/yubikey_identity.pub"
let VARS_FILE = $"($PROJECT_ROOT)/vars.nix"
let SSH_USER = (nix eval --raw -f $VARS_FILE username)
let TARGET_DIR = $"($HOSTS_DIR)/$TARGET_HOSTNAME"
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

def ssh_with_opts [command: string user: string, host = $BOOTSTRAP_HOSTNAME] {
    ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ControlMaster=auto -o ControlPath=$ARTIFACTS/ssh-%r@%h:%p -o ControlPersist=10m $"($user)@($host)" command
}
def scp_with_opts_up [infile: path, outfile: path, user: string, host = $BOOTSTRAP_HOSTNAME] {
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ControlMaster=auto -o ControlPath=$ARTIFACTS/ssh-%r@%h:%p -o ControlPersist=10m $"($user)@($host)" $infile $"($user)@($host):($outfile)"
}
    
def scp_with_opts_down [infile: path, outfile: path, user: string, host = $BOOTSTRAP_HOSTNAME] {
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -o ControlMaster=auto -o ControlPath=$ARTIFACTS/ssh-%r@%h:%p -o ControlPersist=10m $"($user)@($host)" $"($user)@($host):($infile)" $outfile
}

def main [TARGET_HOSTNAME: string] {
    print "==> Checking for $BOOTSTRAP_HOSTNAME...\n"
    try {
        ping -c 1 -W 2 -q $BOOTSTRAP_HOSTNAME
        print "Found host"
     } catch {
        print "Error: Host unreachable"
        exit 1
    }

    if  ($TARGET_DIR | path exists) {
        print $"Error: Host directory $TARGET_DIR already exists."
        exit 1
    }
    
    print $"==> Scaffolding $TARGET_DIR...\n"

    mkdir $HOSTS_DIR
    cp -r $TEMPLATE_DIR $TARGET_DIR

    print "==> Generating Challenge 1...\n"

    openssl rand -hex 32 | save  $"($ARTIFACTS)/c1_nonce.txt"

    $"stage=pre-install host=($TARGET_HOSTNAME) nonce=(open $"($ARTIFACTS)/c1_nonce.txt" | str trim)" | save $"($ARTIFACTS)/c1.txt"

    age -r (
        open $YUBIKEY_PUB | lines | first | split words | last
    ) -o $CHALLENGE_1 $"($ARTIFACTS)/c1.txt"

    prompt_key_local

    print "==> Adding key to agent\n"

    ssh-add -K

    print "==> initial ssh connection\n"

    ssh_with_opts "echo 'Connected to host'" $SSH_USER
    
    print "==> Uploading challenge to $BOOTSTRAP_HOSTNAME...\n"

    scp_with_opts_up $CHALLENGE_1  "/tmp/verify.age" $SSH_USER
    scp_with_opts_up $YUBIKEY_PUB  "/tmp/yubikey_identity.pub"  $SSH_USER

    prompt_key_remote $BOOTSTRAP_HOSTNAME
    
    print "==> Verifying identity on remote...\n"
    ssh_with_opts 'set -euo pipefail; echo "Decrypting..."; age -d -i /tmp/yubikey_identity.pub -o /tmp/verified.txt /tmp/verify.age; echo "Scanning Hardware..."; sudo nixos-facter > /tmp/facter.json' $SSH_USER

    prompt_key_local
    print "==> Retrieving proofs...\n"
    scp_with_opts_down /tmp/verified.txt  $"($ARTIFACTS)/c1_returned.txt" $SSH_USER
    scp_with_opts_down /tmp/facter.json $"($TARGET_DIR)/facter.json" $SSH_USER
    let challenge_match = (open $"($ARTIFACTS)/c1.txt" | str trim) == (open $"($ARTIFACTS)/c1_returned.txt" | str trim)
    if !$challenge_match {
        print "!!!!!! SECURITY ALERT !!!!!!"
        print "Attestation Failed! Remote content does not match local challenge."
        exit 1
    }
     print "==> Identity confirmed." 
}
