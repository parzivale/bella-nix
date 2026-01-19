#!/usr/bin/env -S nix shell nixpkgs#nushell nixpkgs#age nixpkgs#openssl nixpkgs#coreutils nixpkgs#jq --command nu
def main [TARGET_HOSTNAME: string] {
    let BOOTSTRAP_HOSTNAME = "bootstrap.local"
    let ARTIFACTS = (mktemp -d -t bootstrap-XXXXXX | str trim)
    let PROJECT_ROOT = (pwd)
    let HOSTS_DIR = $"($PROJECT_ROOT)/src/hosts"
    let TEMPLATE_DIR = $"($PROJECT_ROOT)/template/host"
    let YUBIKEY_PUB = $"($PROJECT_ROOT)/src/common/secrets/yubikey_identity.pub"
    let VARS_FILE = $"($PROJECT_ROOT)/vars.nix"
    let SSH_OPTS = [
        "-o"
        "StrictHostKeyChecking=no"
        "-o"
        "UserKnownHostsFile=/dev/null"
        "-o"
        "ConnectTimeout=10"
        "-o"
        "ControlMaster=auto"
        "-o"
        "ControlPath=$ARTIFACTS/ssh-%r@%h:%p"
        "-o"
        "ControlPersist=10m"
    ]
    let SSH_USER = (nix eval --raw -f $VARS_FILE username)
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
    echo $"==> Checking for $BOOTSTRAP_HOSTNAME..."
    try { ping -c 1 -W 2 $BOOTSTRAP_HOSTNAME } catch {
        echo "Error: Host unreachable"
        exit 1
    }
    let TARGET_DIR = $"($HOSTS_DIR)/$TARGET_HOSTNAME"
    if (^ls $TARGET_DIR | length) > 0 {
        echo $"Error: Host directory $TARGET_DIR already exists."
        exit 1
    }
    echo $"==> Scaffolding $TARGET_DIR..."
    mkdir $HOSTS_DIR
    cp -r $TEMPLATE_DIR $TARGET_DIR
    echo "==> Generating Challenge 1..."
    let CHALLENGE_1 = $"($ARTIFACTS)/c1.age"
    openssl rand -hex 32 > $"($ARTIFACTS)/c1_nonce.txt"
    echo $"stage=pre-install host=$TARGET_HOSTNAME nonce=(open $"($ARTIFACTS)/c1_nonce.txt" | str trim)" > $"($ARTIFACTS)/c1.txt"
    age -r (
        open $YUBIKEY_PUB | lines | first | split words | last
    ) -o $CHALLENGE_1 $"($ARTIFACTS)/c1.txt"
    prompt_key_local
    echo "==> Adding key to agent"
    ssh-add -K
    echo "==> initial ssh connection"
    ssh $SSH_OPTS "$SSH_USER@$BOOTSTRAP_HOSTNAME" "echo 'connected to host'"
    echo "==> Uploading challenge to $BOOTSTRAP_HOSTNAME..."
    scp $SSH_OPTS $CHALLENGE_1 "$SSH_USER@$BOOTSTRAP_HOSTNAME:/tmp/verify.age"
    scp $SSH_OPTS $YUBIKEY_PUB "$SSH_USER@$BOOTSTRAP_HOSTNAME:/tmp/yubikey_identity.pub"
    # --- SWAP 2: REMOTE ---
    prompt_key_remote $BOOTSTRAP_HOSTNAME
    echo "==> Verifying identity on remote..."
    ssh -t $SSH_OPTS "$SSH_USER@$BOOTSTRAP_HOSTNAME" '
    set -euo pipefail
    echo "Decrypting..."
    age -d -i /tmp/yubikey_identity.pub -o /tmp/verified.txt /tmp/verify.age
    echo "Scanning Hardware..."
    sudo nixos-facter > /tmp/facter.json
'
    prompt_key_local
    echo "==> Retrieving proofs..."
    scp $SSH_OPTS "$SSH_USER@$BOOTSTRAP_HOSTNAME:/tmp/verified.txt" $"($ARTIFACTS)/c1_returned.txt"
    scp $SSH_OPTS "$SSH_USER@$BOOTSTRAP_HOSTNAME:/tmp/facter.json" $"($TARGET_DIR)/facter.json"
    let challenge_match = (open $"($ARTIFACTS)/c1.txt" | str trim) == (open $"($ARTIFACTS)/c1_returned.txt" | str trim)
    if !$challenge_match {
        echo "!!!!!! SECURITY ALERT !!!!!!"
        echo "Attestation Failed! Remote content does not match local challenge."
        exit 1
    } else { echo "==> Identity confirmed." }
}
