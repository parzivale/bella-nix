use utility.nu *
use constants.nu *

export def --env main [addr: string, TARGET_DIR: string, host_key_checking: bool = true]: nothing -> nothing {
    let challenge = $"(artifacts)/c1.txt"
    let challenge_encrypted = $"(artifacts)/c1.age"
    let returned_challenge = $"(artifacts)/c1_returned.txt"
    let ssh_user = user

    print "==> Generating Challenge...\n"
    openssl rand -hex 32 | str trim | save $challenge
    age -r (
        open $YUBIKEY_PUB | lines | first | split words | last
    ) -o $challenge_encrypted $"(artifacts)/c1.txt"

    print $"==> Uploading challenge to ($BOOTSTRAP_HOSTNAME)...\n"
    utility scp_with_opts_up $challenge_encrypted "/tmp/verify.age" $ssh_user $addr
    scp_up $YUBIKEY_PUB "/tmp/yubikey_identity.pub" $ssh_user $addr
    prompt_key_remote $BOOTSTRAP_HOSTNAME
    print "==> Verifying identity on remote...\n"
    ssh_with_opts $'set -euo pipefail; echo "Decrypting..."; age -d -i /tmp/yubikey_identity.pub -o /tmp/verified.txt /tmp/verify.age' $ssh_user $addr $host_key_checking
    prompt_key_local
    print "==> Retrieving proof...\n"
    scp_down /tmp/verified.txt $returned_challenge $ssh_user $addr
    let challenge_match = (open $challenge | str trim) == (open $returned_challenge | str trim)

    if not $challenge_match {
        print "!!!!!! SECURITY ALERT !!!!!!"
        print "Attestation Failed! Remote content does not match local challenge."
        exit 1
    }

    print "==> Identity confirmed."
}
