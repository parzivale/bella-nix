#!/usr/bin/env nu

let root = $env.FILE_PWD | path join ..
let secrets_dir = $root | path join src secrets xray

mkdir $secrets_dir

let uuid = (uuidgen | str trim)
let short_id = (openssl rand -hex 8 | str trim)

let keypair = (xray x25519)
let private_key = (
    $keypair | lines
    | where { |l| $l | str starts-with "PrivateKey:" }
    | first | str replace "PrivateKey: " "" | str trim
)
let public_key = (
    $keypair | lines
    | where { |l| $l | str starts-with "Password" }
    | first | str replace "Password (PublicKey): " "" | str trim
)

let tmp = (^mktemp | str trim)

def encrypt [content: string, out: string] {
    $content | save -f $tmp
    ^agenix edit --input $tmp $out
}

encrypt $"XRAY_UUID=($uuid)\nXRAY_PRIVATE_KEY=($private_key)\nXRAY_SHORT_ID=($short_id)" ($secrets_dir | path join reality-server.age | path expand)
encrypt $"XRAY_UUID=($uuid)" ($secrets_dir | path join xhttp-server.age | path expand)
encrypt $"XRAY_UUID=($uuid)\nXRAY_PUBLIC_KEY=($public_key)\nXRAY_SHORT_ID=($short_id)\nXRAY_SERVER_ADDR=" ($secrets_dir | path join reality-client.age | path expand)
encrypt $"XRAY_UUID=($uuid)" ($secrets_dir | path join xhttp-client.age | path expand)

rm $tmp

print "Done. Fill in XRAY_SERVER_ADDR in reality-client.age with: agenix edit src/secrets/xray/reality-client.age"
